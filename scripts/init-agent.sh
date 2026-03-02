#!/bin/bash
# ====================================================
# Inicializar um novo agente no OpenClaw
# Uso: ./init-agent.sh <agent-id> <agent-name> <description>
# ====================================================

set -euo pipefail

if [ $# -lt 3 ]; then
    echo "Uso: $0 <agent-id> <agent-name> <description>"
    echo "Exemplo: $0 tutor-math 'Math Tutor' 'Tutor de matemática'"
    exit 1
fi

AGENT_ID=$1
AGENT_NAME=$2
AGENT_DESC=$3

OPENCLAW_HOME="${OPENCLAW_HOME:-/home/openclaw/.openclaw}"

log() { echo -e "\033[0;32m[init]\033[0m $1"; }

log "🆕 Criando novo agente: $AGENT_NAME ($AGENT_ID)"

# Criar estrutura
mkdir -p "${OPENCLAW_HOME}/agents/${AGENT_ID}/agent"/{knowledge,tools,logs}
mkdir -p "${OPENCLAW_HOME}/workspace-${AGENT_ID}"

# Criar system.md
cat > "${OPENCLAW_HOME}/agents/${AGENT_ID}/agent/system.md" <<EOF
# $AGENT_NAME

## Identidade
$AGENT_DESC

## Especialidades
[Definir especialidades]

## Metodologia
[Definir metodologia]

## Regras
[Definir regras]
EOF

# Criar agent.json
cat > "${OPENCLAW_HOME}/agents/${AGENT_ID}/agent/agent.json" <<EOF
{
  "id": "$AGENT_ID",
  "name": "$AGENT_NAME",
  "description": "$AGENT_DESC",
  "version": "1.0.0",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Adicionar ao openclaw.json
log "📝 Atualizando openclaw.json..."
# (Aqui você pode usar jq para modificar o JSON programaticamente)

log "✅ Agente criado com sucesso!"
log "   Diretório: ${OPENCLAW_HOME}/agents/${AGENT_ID}"
log "   Workspace: ${OPENCLAW_HOME}/workspace-${AGENT_ID}"
log "\nPróximos passos:"
log "1. Edite: ${OPENCLAW_HOME}/agents/${AGENT_ID}/agent/system.md"
log "2. Adicione knowledge em: ${OPENCLAW_HOME}/agents/${AGENT_ID}/agent/knowledge/"
log "3. Registre no openclaw.json"
log "4. Reinicie: docker-compose restart openclaw"
