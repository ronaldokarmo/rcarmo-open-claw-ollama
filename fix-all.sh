#!/bin/bash
# ========================================
# Script de Correção Completa OpenClaw
# Corrige permissões e aplica configuração
# ========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[fix]${NC} $1"; }
warn() { echo -e "${YELLOW}[fix]${NC} $1"; }
error() { echo -e "${RED}[fix]${NC} $1" >&2; }
info() { echo -e "${BLUE}[info]${NC} $1"; }

clear
cat << "EOF"
╔══════════════════════════════════════════════╗
║                                              ║
║     🔧 OpenClaw - Correção Completa 🔧      ║
║                                              ║
║  Corrige permissões e aplica configuração   ║
║                                              ║
╚══════════════════════════════════════════════╝
EOF
echo ""

# Verificar diretório
if [ ! -f "docker-compose.yml" ]; then
    error "❌ Execute este script no diretório openclaw-docker"
    exit 1
fi

log "✅ Diretório correto detectado"

# Parar container
log "⏸️  Parando container OpenClaw..."
docker-compose stop openclaw 2>/dev/null || true

# Criar estrutura
log "📁 Criando/verificando estrutura de diretórios..."
mkdir -p data/.openclaw

# Backup
if [ -f "data/.openclaw/openclaw.json" ]; then
    BACKUP_FILE="data/.openclaw/openclaw.json.backup.$(date +%Y%m%d_%H%M%S)"
    log "💾 Fazendo backup: $BACKUP_FILE"
    sudo cp data/.openclaw/openclaw.json "$BACKUP_FILE"
fi

# Copiar configuração otimizada
if [ -f "openclaw-multiagent-optimized.json" ]; then
    log "📝 Aplicando configuração otimizada para 11GB RAM..."
    sudo cp openclaw-multiagent-optimized.json data/.openclaw/openclaw.json
    log "✅ Configuração aplicada"
else
    warn "⚠️  openclaw-multiagent-optimized.json não encontrado"
    info "   Criando configuração mínima válida..."
    
    # Criar configuração mínima
    sudo tee data/.openclaw/openclaw.json > /dev/null << 'JSONEOF'
{
  "meta": {
    "lastTouchedVersion": "2026.2.28"
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/llama3.2:3b"
      }
    },
    "list": [
      {
        "id": "main",
        "name": "main",
        "workspace": "/home/openclaw/.openclaw/workspace",
        "agentDir": "/home/openclaw/.openclaw/agents/main/agent"
      }
    ]
  },
  "channels": {
    "telegram": {
      "enabled": true
    }
  },
  "gateway": {
    "port": 18790,
    "mode": "local"
  }
}
JSONEOF
fi

# Corrigir permissões
log "🔐 Corrigindo permissões..."
sudo chown -R 1000:1000 data/.openclaw/
sudo chmod -R 755 data/.openclaw/
sudo find data/.openclaw -type f -name "*.json" -exec chmod 644 {} \;
sudo find data/.openclaw -type f -name "*.md" -exec chmod 644 {} \;

# Verificar
echo ""
info "📋 Verificação de Permissões:"
ls -lah data/.openclaw/openclaw.json

# Verificar conteúdo do arquivo
if sudo cat data/.openclaw/openclaw.json > /dev/null 2>&1; then
    log "✅ Arquivo legível"
else
    error "❌ Arquivo ainda não legível!"
    exit 1
fi

# Reiniciar
echo ""
log "🚀 Reiniciando OpenClaw..."
docker-compose up -d openclaw

# Aguardar inicialização
log "⏳ Aguardando inicialização (10 segundos)..."
sleep 10

# Verificar status
echo ""
info "📊 Status do Container:"
docker-compose ps openclaw

# Verificar se está rodando
if docker-compose ps openclaw | grep -q "Up"; then
    log "✅ OpenClaw está rodando!"
    
    # Verificar logs por erros
    if docker-compose logs openclaw | grep -q "EACCES"; then
        error "❌ Ainda há erros de permissão nos logs!"
        echo ""
        info "Últimas linhas do log:"
        docker-compose logs --tail=30 openclaw
        exit 1
    elif docker-compose logs openclaw | grep -q "listening on ws://"; then
        log "✅ Gateway iniciado com sucesso!"
        
        # Testar endpoint
        if curl -sf http://localhost:18790/ > /dev/null 2>&1; then
            log "✅ Endpoint respondendo!"
        else
            warn "⚠️  Endpoint não responde (pode estar configurado diferente)"
        fi
    else
        warn "⚠️  Gateway pode não ter iniciado corretamente"
    fi
else
    error "❌ OpenClaw não está rodando!"
    echo ""
    info "Últimas linhas do log:"
    docker-compose logs --tail=30 openclaw
    exit 1
fi

echo ""
info "📜 Últimas 25 linhas do log:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker-compose logs --tail=25 openclaw
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
log "✅ Correção concluída!"
echo ""
info "📋 Comandos úteis:"
echo "  • Monitorar logs:  docker-compose logs -f openclaw"
echo "  • Verificar status: docker-compose ps"
echo "  • Reiniciar:       docker-compose restart openclaw"
echo "  • Parar:           docker-compose stop openclaw"
echo ""
info "🌐 Interfaces:"
echo "  • Web UI:    http://localhost:18790"
echo "  • Telegram:  Envie /start para @pi_test_engineer_bot"
echo ""

# Perguntar se quer monitorar logs
read -p "Deseja monitorar os logs agora? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    log "📊 Monitorando logs (Ctrl+C para sair)..."
    docker-compose logs -f openclaw
fi
