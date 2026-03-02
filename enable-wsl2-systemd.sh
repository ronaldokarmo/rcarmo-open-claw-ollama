#!/bin/bash
# ========================================
# Script para Habilitar systemd no WSL2
# Execute este script DENTRO do WSL2
# ========================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[systemd-setup]${NC} $1"; }
warn() { echo -e "${YELLOW}[systemd-setup]${NC} $1"; }
error() { echo -e "${RED}[systemd-setup]${NC} $1"; }
info() { echo -e "${BLUE}[info]${NC} $1"; }

clear
cat << "EOF"
╔══════════════════════════════════════════════╗
║                                              ║
║     🐧 Habilitar systemd no WSL2 🐧         ║
║                                              ║
╚══════════════════════════════════════════════╝
EOF
echo ""

# Verificar se está no WSL2
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    error "❌ Este script deve ser executado DENTRO do WSL2!"
    exit 1
fi

log "✅ WSL2 detectado"
echo ""

# Verificar se systemd já está habilitado
if systemctl --version >/dev/null 2>&1; then
    log "✅ systemd já está habilitado!"
    info "   Versão: $(systemctl --version | head -1)"
    echo ""
    info "Nada a fazer. Seu WSL2 já está configurado corretamente."
    exit 0
fi

warn "⚠️  systemd NÃO está habilitado"
echo ""

# Verificar se /etc/wsl.conf existe
if [ -f /etc/wsl.conf ]; then
    info "📄 Arquivo /etc/wsl.conf encontrado"
    
    # Verificar se já tem configuração systemd
    if grep -q "^\[boot\]" /etc/wsl.conf && grep -q "^systemd=true" /etc/wsl.conf; then
        log "✅ Configuração systemd já existe em /etc/wsl.conf"
        warn "⚠️  Mas systemd não está ativo. Você reiniciou o WSL?"
        echo ""
        info "Execute no PowerShell: wsl --shutdown"
        info "Depois reabra o WSL2"
        exit 0
    fi
    
    log "📝 Fazendo backup de /etc/wsl.conf..."
    sudo cp /etc/wsl.conf /etc/wsl.conf.backup.$(date +%Y%m%d_%H%M%S)
else
    info "📄 Arquivo /etc/wsl.conf não existe. Será criado."
fi

echo ""
log "📝 Configurando systemd..."

# Criar ou atualizar /etc/wsl.conf
if [ -f /etc/wsl.conf ]; then
    # Arquivo existe, adicionar [boot] se não existir
    if ! grep -q "^\[boot\]" /etc/wsl.conf; then
        log "   Adicionando seção [boot]..."
        echo "" | sudo tee -a /etc/wsl.conf >/dev/null
        echo "[boot]" | sudo tee -a /etc/wsl.conf >/dev/null
        echo "systemd=true" | sudo tee -a /etc/wsl.conf >/dev/null
    elif ! grep -q "^systemd=true" /etc/wsl.conf; then
        log "   Adicionando systemd=true..."
        sudo sed -i '/^\[boot\]/a systemd=true' /etc/wsl.conf
    fi
else
    # Arquivo não existe, criar do zero
    log "   Criando /etc/wsl.conf..."
    sudo tee /etc/wsl.conf >/dev/null << 'WSLCONF'
[boot]
systemd=true

[network]
generateResolvConf = true

[interop]
enabled = true
appendWindowsPath = true
WSLCONF
fi

echo ""
log "✅ Configuração aplicada!"

# Mostrar conteúdo
echo ""
info "📄 Conteúdo de /etc/wsl.conf:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat /etc/wsl.conf
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Instruções finais
echo ""
cat << "INSTRUCTIONS"
╔════════════════════════════════════════════════════════════════╗
║                  ✅ CONFIGURAÇÃO CONCLUÍDA                     ║
╚════════════════════════════════════════════════════════════════╝

📋 PRÓXIMOS PASSOS:

1. Feche TODAS as janelas do WSL2

2. No PowerShell (Windows), execute:
   
   wsl --shutdown

3. Aguarde 5 segundos

4. Reabra o WSL2 (Ubuntu, Debian, etc)

5. Verifique se systemd está ativo:
   
   systemctl --version

   Deve mostrar a versão do systemd

6. Teste o Docker:
   
   sudo systemctl status docker

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 DICA: Se o docker não estiver rodando após reiniciar:

   sudo systemctl start docker
   sudo systemctl enable docker

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSTRUCTIONS

echo ""
info "Agora execute 'wsl --shutdown' no PowerShell e reabra o WSL2!"
echo ""
