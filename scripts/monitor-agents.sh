#!/bin/bash
# ====================================================
# Monitor de status dos agentes OpenClaw
# ====================================================

set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-/home/openclaw/.openclaw}"

log() { echo -e "\033[0;32m[monitor]\033[0m $1"; }

clear
echo "╔══════════════════════════════════════════════╗"
echo "║     OpenClaw Multiagent Monitor              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Listar agentes
echo "📋 Agentes Registrados:"
echo ""

for agent_dir in "${OPENCLAW_HOME}/agents"/*/; do
    agent_id=$(basename "$agent_dir")
    
    # Ler metadados
    if [ -f "$agent_dir/agent/agent.json" ]; then
        agent_name=$(jq -r '.name // "N/A"' "$agent_dir/agent/agent.json" 2>/dev/null || echo "N/A")
        agent_desc=$(jq -r '.description // "N/A"' "$agent_dir/agent/agent.json" 2>/dev/null || echo "N/A")
    else
        agent_name="N/A"
        agent_desc="N/A"
    fi
    
    # Verificar logs recentes
    log_count=$(find "$agent_dir/logs" -name "*.log" 2>/dev/null | wc -l || echo 0)
    
    # Verificar workspace
    workspace_size=$(du -sh "${OPENCLAW_HOME}/workspace-${agent_id}" 2>/dev/null | cut -f1 || echo "N/A")
    
    echo "┌─ $agent_id"
    echo "│  Nome: $agent_name"
    echo "│  Descrição: $agent_desc"
    echo "│  Logs: $log_count arquivos"
    echo "│  Workspace: $workspace_size"
    echo "└─"
    echo ""
done

# Status do gateway
echo "🌐 Gateway Status:"
if curl -sf http://localhost:18790/ >/dev/null 2>&1; then
    echo "   ✅ Gateway rodando (porta 18790)"
else
    echo "   ❌ Gateway offline"
fi
echo ""

# Status do Ollama
echo "🤖 Ollama Status:"
if curl -sf "${OLLAMA_API_BASE:-http://localhost:11434}/api/tags" >/dev/null 2>&1; then
    echo "   ✅ Ollama conectado"
    ollama_models=$(curl -sf "${OLLAMA_API_BASE:-http://localhost:11434}/api/tags" | jq -r '.models[].name' 2>/dev/null | wc -l || echo 0)
    echo "   📦 Modelos disponíveis: $ollama_models"
else
    echo "   ❌ Ollama offline"
fi
echo ""

# Telegram
echo "📱 Telegram Bot:"
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
    echo "   ✅ Token configurado"
else
    echo "   ⚠️  Token não configurado"
fi
echo ""

log "Pressione Ctrl+C para sair. Atualizando a cada 5s..."
sleep 5
exec "$0"
