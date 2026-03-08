#!/bin/bash
# ================================================================
#  INSTALADOR OPENCLAW - Ubuntu 24.04 LTS
#  Detecta automaticamente: RAM, CPU cores, tipo de VPS
#  Otimiza heap Node.js e paralelismo para o hardware disponivel
# ================================================================
set -e

# ── Cores para output ─────────────────────────────────────────
GRN='\033[0;32m' CYN='\033[0;36m' YLW='\033[1;33m' RED='\033[0;31m' RST='\033[0m' BLD='\033[1m'
ok()   { echo -e "${GRN}[OK]${RST} $1"; }
info() { echo -e "${CYN}[..] $1${RST}"; }
warn() { echo -e "${YLW}[!!] $1${RST}"; }
fail() { echo -e "${RED}[XX] $1${RST}"; exit 1; }

echo -e "\n${BLD}OpenClaw Installer — Ubuntu 24.04 LTS${RST}\n"

# ── Verifica root ──────────────────────────────────────────────
[ "$(id -u)" -eq 0 ] || fail "Execute como root: sudo bash install.sh"

# ── Detecta RAM, CPU e perfil ─────────────────────────────────
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_GB=$(( RAM_KB / 1024 / 1024 ))
CPU_TOTAL=$(nproc --all)
CPU_PERF=$(nproc)

# VPS tem menos overhead que desktop — reserva 1-2 GB para o SO
if   [ "$RAM_GB" -ge 64 ]; then OS_RESERVE=4
elif [ "$RAM_GB" -ge 32 ]; then OS_RESERVE=3
elif [ "$RAM_GB" -ge 16 ]; then OS_RESERVE=2
elif [ "$RAM_GB" -ge  8 ]; then OS_RESERVE=2
else                             OS_RESERVE=1; fi

NODE_HEAP_MB=$(( (RAM_GB - OS_RESERVE) * 1024 ))
PNPM_WORKERS=$(( CPU_PERF * 4 / 5 ))
[ "$PNPM_WORKERS" -lt 2 ] && PNPM_WORKERS=2

# Flags extras por quantidade de RAM (sem geracoes de chip no Linux)
if   [ "$RAM_GB" -ge 16 ]; then NODE_EXTRA="--turbofan --max-semi-space-size=256"
elif [ "$RAM_GB" -ge  8 ]; then NODE_EXTRA="--turbofan --max-semi-space-size=128"
else                             NODE_EXTRA="--max-semi-space-size=64"; fi

echo -e "  RAM:   ${BLD}${RAM_GB} GB${RST}  |  Heap Node.js: ${BLD}$(( NODE_HEAP_MB / 1024 )) GB${RST}"
echo -e "  Cores: ${BLD}${CPU_TOTAL}${RST}       |  Workers pnpm: ${BLD}${PNPM_WORKERS}${RST}\n"

# ── 1. Atualiza sistema ───────────────────────────────────────
info "Atualizando sistema..."
apt-get update -qq && apt-get upgrade -y -qq
ok "Sistema atualizado"

# ── 2. Dependencias de build ──────────────────────────────────
info "Instalando build tools..."
apt-get install -y -qq build-essential git curl ca-certificates gnupg
ok "Build tools prontos"

# ── 3. Node.js 22 via NodeSource ─────────────────────────────
if command -v node >/dev/null 2>&1 && [ "$(node --version | cut -d. -f1 | tr -d v)" -ge 22 ]; then
  ok "Node.js $(node --version) ja instalado"
else
  info "Instalando Node.js 22..."
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash - >/dev/null 2>&1
  apt-get install -y -qq nodejs
  ok "Node.js $(node --version) instalado"
fi

# ── 4. pnpm ───────────────────────────────────────────────────
if command -v pnpm >/dev/null 2>&1; then
  ok "pnpm $(pnpm --version) ja instalado"
else
  info "Instalando pnpm..."
  npm install -g pnpm --quiet
  ok "pnpm $(pnpm --version) instalado"
fi

# ── 5. Clone + build ──────────────────────────────────────────
INSTALL_DIR="/opt/openclaw"
info "Clonando repositorio..."
[ -d "$INSTALL_DIR" ] && rm -rf "$INSTALL_DIR"
git clone --depth 1 https://github.com/openclaw/openclaw.git "$INSTALL_DIR" -q
ok "Repositorio clonado em $INSTALL_DIR"

info "Compilando com otimizacoes (heap: $(( NODE_HEAP_MB / 1024 )) GB)..."
cd "$INSTALL_DIR"
PNPM_CONCURRENCY=$PNPM_WORKERS pnpm install --silent
NODE_OPTIONS="--max-old-space-size=${NODE_HEAP_MB} ${NODE_EXTRA}" pnpm run build
ok "Build concluido"

# ── 6. Wrapper global com perfil permanente ───────────────────
info "Criando comando global..."
W_PATH="${INSTALL_DIR}/openclaw.mjs"

cat > /usr/local/bin/openclaw << WRAPPER
#!/bin/bash
# OpenClaw — Ubuntu $(lsb_release -rs) | ${RAM_GB}GB RAM | perfil auto-detectado
export NODE_OPTIONS="--max-old-space-size=${NODE_HEAP_MB} ${NODE_EXTRA}"
export UV_THREADPOOL_SIZE=${CPU_TOTAL}
exec node "${W_PATH}" "\$@"
WRAPPER

chmod +x /usr/local/bin/openclaw
ok "Comando 'openclaw' disponivel globalmente"

# ── 7. Salva perfil de instalacao ─────────────────────────────
mkdir -p /opt/openclaw/.meta
cat > /opt/openclaw/.meta/install-profile.txt << PROFILE
Instalado em: $(date)
Ubuntu: $(lsb_release -ds)
RAM total: ${RAM_GB} GB
Heap Node.js: $(( NODE_HEAP_MB / 1024 )) GB
CPU cores: ${CPU_TOTAL}
Workers pnpm: ${PNPM_WORKERS}
Node.js: $(node --version)
pnpm: $(pnpm --version)
NODE_OPTIONS: --max-old-space-size=${NODE_HEAP_MB} ${NODE_EXTRA}
UV_THREADPOOL_SIZE: ${CPU_TOTAL}
PROFILE

# ── 8. Verificacao final ──────────────────────────────────────
echo ""
echo -e "${BLD}─────────────────────────────────────────${RST}"
echo -e "${GRN}${BLD}  OpenClaw instalado com sucesso${RST}"
echo -e "${BLD}─────────────────────────────────────────${RST}"
echo -e "  Node.js:  $(node --version)"
echo -e "  pnpm:     $(pnpm --version)"
echo -e "  Heap:     $(( NODE_HEAP_MB / 1024 )) GB de ${RAM_GB} GB"
echo -e "  Perfil:   /opt/openclaw/.meta/install-profile.txt"
echo ""
echo -e "${YLW}${BLD}  PROXIMO PASSO OBRIGATORIO:${RST}"
echo -e "  ${CYN}openclaw onboard${RST}"
echo ""
