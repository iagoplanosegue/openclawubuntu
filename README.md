 ⬡ OpenClaw — Ubuntu 24.04 LTS

[![Versão](https://img.shields.io/badge/versão-1.0.0-e95420?style=flat-square&labelColor=0d1117)](https://github.com/iagoplanosegue/openclawubuntu)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04_LTS-e95420?style=flat-square&logo=ubuntu&logoColor=white&labelColor=0d1117)](https://ubuntu.com)
[![Node.js](https://img.shields.io/badge/Node.js-22-339933?style=flat-square&logo=node.js&logoColor=white&labelColor=0d1117)](https://nodejs.org)
[![Licença](https://img.shields.io/badge/licença-MIT-f5a623?style=flat-square&labelColor=0d1117)](./LICENSE)

> Script de instalação otimizado para OpenClaw em Ubuntu 24.04 LTS.  
> Detecta RAM e CPU automaticamente. Heap máximo com reserva mínima para o SO — sem GUI, sem overhead.

---

## 📋 Pré-requisitos

**1. Acesso root ou sudo**
```bash
sudo -i
```

**2. Confirmar Ubuntu 24.04**
```bash
lsb_release -a
```

**3. Verificar conexão**
```bash
curl -I https://github.com
```

---

## ⚡ Instalação rápida

```bash
curl -fsSL https://raw.githubusercontent.com/iagoplanosegue/openclawubuntu/main/install.sh | sudo bash
```

Depois de concluir:

```bash
openclaw onboard
```

---

## 🖥️ VPS suportadas

| RAM | Heap Node.js | Reserva SO | Flags |
|-----|:-----------:|:----------:|-------|
| 4 GB | 3 GB | 1 GB | `--max-semi-space-size=64` |
| 8 GB | 6 GB | 2 GB | `--turbofan --max-semi-space-size=128` |
| 16 GB | 14 GB | 2 GB | `--turbofan --max-semi-space-size=256` |
| 32 GB | 29 GB | 3 GB | `--turbofan --max-semi-space-size=256` |
| 64 GB+ | 60 GB | 4 GB | `--turbofan --max-semi-space-size=256` |

> VPS não tem interface gráfica — o SO precisa de apenas 1~2 GB, liberando muito mais para o Node.js.


---


## 🔍 O que o script faz

```
1. Verifica se está rodando como root
2. Detecta RAM total via /proc/meminfo
3. Detecta cores via nproc
4. Calcula heap ideal (RAM - reserva SO)
5. Atualiza o sistema via apt-get
6. Instala build-essential, git, curl, gnupg
7. Instala Node.js 22 via NodeSource
8. Instala pnpm
9. Clona OpenClaw em /opt/openclaw
10. Compila com otimizações para o hardware detectado
11. Cria wrapper global em /usr/local/bin/openclaw
12. Salva perfil de instalação em /opt/openclaw/.meta/
```

---

## ❓ FAQ

**Precisa de sudo?**  
Sim. O script instala pacotes via `apt`, clona em `/opt` e cria o comando em `/usr/local/bin`. Tudo requer permissão de root.

**Funciona em VPS de 2 GB?**  
Sim, mas com limitações. O heap ficará em ~1 GB. Para uso intenso, recomendamos VPS de 4 GB+.

**Funciona em Ubuntu 22.04?**  
O script foi desenvolvido e testado para 24.04 LTS. Pode funcionar no 22.04, mas não é garantido.

**Como atualizar o OpenClaw?**  
Rode o script novamente. Ele limpa `/opt/openclaw` e faz uma instalação limpa.

**O Node.js vai conflitar com versões existentes?**  
O script verifica se já existe Node 22+ antes de instalar. Se já estiver presente, pula essa etapa.

---

## 🐛 Reportar problemas

Abra uma [issue](https://github.com/iagoplanosegue/openclawubuntu/issues) com:

```bash
# Cole a saída desses comandos na issue:
lsb_release -a
grep MemTotal /proc/meminfo
nproc
node --version 2>/dev/null || echo "Node nao instalado"
cat /opt/openclaw/.meta/install-profile.txt 2>/dev/null || echo "Perfil nao encontrado"
```

---

## 📝 Changelog

### [1.0.0] — 2026-03-08
- Versão inicial para Ubuntu 24.04 LTS
- Detecção automática de RAM via `/proc/meminfo`
- Detecção de cores via `nproc`
- Perfis de heap por quantidade de RAM (1~4 GB reserva)
- Node.js 22 via NodeSource
- Wrapper global em `/usr/local/bin` com `NODE_OPTIONS` permanente
- Output colorido com `[OK]`, `[..]`, `[XX]`
- Perfil de instalação salvo em `/opt/openclaw/.meta/`

---

## 📄 Licença

MIT © [Iago Plano Segue](https://github.com/iagoplanosegue)

---

<div align="center">
  <sub>Guia completo em <a href="https://planosegue.com/ubuntu">planosegue.com/ubuntu</a> &nbsp;·&nbsp; Versão macOS em <a href="https://planosegue.com/ubuntu">planosegue.com/ubuntu</a></sub>
</div>
