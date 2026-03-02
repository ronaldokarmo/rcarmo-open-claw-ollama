#!/bin/bash
# ====================================================
# Setup de Multiagentes OpenClaw
# Cria estrutura de diretórios e arquivos de configuração
# ====================================================

set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-/home/openclaw/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo -e "\033[0;32m[setup]\033[0m $1"; }
warn() { echo -e "\033[1;33m[setup]\033[0m $1"; }
error() { echo -e "\033[0;31m[setup]\033[0m $1" >&2; }

# ====================================================
# Função: Criar estrutura de diretórios
# ====================================================
create_agent_structure() {
    local agent_id=$1
    local agent_name=$2
    local description=$3
    
    log "📁 Criando estrutura para agente: $agent_name"
    
    local agent_dir="${OPENCLAW_HOME}/agents/${agent_id}/agent"
    local workspace="${OPENCLAW_HOME}/workspace-${agent_id}"
    
    # Criar diretórios
    mkdir -p "$agent_dir"/{knowledge,tools,logs}
    mkdir -p "$workspace"
    
    # Criar arquivo de metadados
    cat > "$agent_dir/agent.json" <<EOF
{
  "id": "$agent_id",
  "name": "$agent_name",
  "description": "$description",
  "version": "1.0.0",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "workspace": "$workspace"
}
EOF
    
    log "✅ Estrutura criada em: $agent_dir"
}

# ====================================================
# Função: Criar system prompt
# ====================================================
create_system_prompt() {
    local agent_id=$1
    local prompt_file=$2
    
    log "📝 Criando system prompt para: $agent_id"
    
    local agent_dir="${OPENCLAW_HOME}/agents/${agent_id}/agent"
    
    if [ ! -f "$prompt_file" ]; then
        warn "⚠️  Arquivo de prompt não encontrado: $prompt_file"
        warn "   Criando placeholder..."
        
        cat > "$agent_dir/system.md" <<EOF
# ${agent_id^} Agent

## Identidade
[Definir a identidade e propósito do agente]

## Especialidades
[Listar áreas de especialização]

## Metodologia
[Descrever como o agente deve abordar tarefas]

## Recursos Disponíveis
- Base de conhecimento em \`knowledge/\`
- Ferramentas em \`tools/\`

## Regras
[Definir regras e restrições]
EOF
    else
        cp "$prompt_file" "$agent_dir/system.md"
    fi
    
    log "✅ System prompt criado"
}

# ====================================================
# Função: Inicializar knowledge base
# ====================================================
init_knowledge_base() {
    local agent_id=$1
    shift
    local kb_files=("$@")
    
    log "📚 Inicializando knowledge base para: $agent_id"
    
    local kb_dir="${OPENCLAW_HOME}/agents/${agent_id}/agent/knowledge"
    
    for kb_file in "${kb_files[@]}"; do
        if [ -f "$kb_file" ]; then
            cp "$kb_file" "$kb_dir/"
            log "   ✓ Copiado: $(basename "$kb_file")"
        else
            warn "   ⚠️  Não encontrado: $kb_file"
        fi
    done
    
    # Criar índice
    cat > "$kb_dir/index.md" <<EOF
# Knowledge Base Index

## Arquivos Disponíveis
$(ls -1 "$kb_dir" | grep -v index.md | sed 's/^/- /')

Última atualização: $(date)
EOF
    
    log "✅ Knowledge base inicializada"
}

# ====================================================
# MAIN
# ====================================================
main() {
    log "🚀 Iniciando setup de multiagentes OpenClaw"
    log "   Home: $OPENCLAW_HOME"
    
    # Verificar se OpenClaw está instalado
    if ! command -v openclaw &> /dev/null; then
        error "❌ OpenClaw não encontrado. Instale primeiro."
        exit 1
    fi
    
    # 1. Agente Main (já existe, apenas validar)
    log "\n=== Agente: main ==="
    if [ -d "${OPENCLAW_HOME}/agents/main" ]; then
        log "✅ Agente main já existe"
    else
        create_agent_structure "main" "Main Coordinator" "Agente principal que roteia conversas"
        create_system_prompt "main" "${SCRIPT_DIR}/../config/agents/main-system.md"
    fi
    
    # 2. Tutor English
    log "\n=== Agente: tutor-english ==="
    create_agent_structure "tutor-english" "English Tutor" "Tutor especializado em ensino de inglês"
    create_system_prompt "tutor-english" "${SCRIPT_DIR}/../config/agents/tutor-english-system.md"
    init_knowledge_base "tutor-english" \
        "${SCRIPT_DIR}/../knowledge/english/grammar-rules.md" \
        "${SCRIPT_DIR}/../knowledge/english/vocabulary-exercises.md"
    
    # 3. Tutor IoT
    log "\n=== Agente: tutor-iot ==="
    create_agent_structure "tutor-iot" "IoT Tutor" "Especialista em IoT, Arduino e eletrônica"
    create_system_prompt "tutor-iot" "${SCRIPT_DIR}/../config/agents/tutor-iot-system.md"
    init_knowledge_base "tutor-iot" \
        "${SCRIPT_DIR}/../knowledge/iot/arduino-ref.md" \
        "${SCRIPT_DIR}/../knowledge/iot/esp32-pinout.md" \
        "${SCRIPT_DIR}/../knowledge/iot/sensor-database.json"
    
    # 4. Ajustar permissões
    log "\n📁 Ajustando permissões..."
    chown -R openclaw:openclaw "${OPENCLAW_HOME}/agents"
    chown -R openclaw:openclaw "${OPENCLAW_HOME}/workspace"*
    chmod -R 750 "${OPENCLAW_HOME}/agents"
    
    # 5. Verificar configuração
    log "\n🔍 Verificando configuração..."
    openclaw doctor || warn "⚠️  Alguns checks falharam (pode ser normal)"
    
    log "\n✨ Setup concluído com sucesso!"
    log "\nPróximos passos:"
    log "1. Edite os system prompts em: ${OPENCLAW_HOME}/agents/*/agent/system.md"
    log "2. Adicione knowledge base em: ${OPENCLAW_HOME}/agents/*/agent/knowledge/"
    log "3. Reinicie o OpenClaw: docker-compose restart openclaw"
    log "4. Teste os agentes via Telegram ou gateway"
}

main "$@"
