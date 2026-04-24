#!/bin/bash

# ────────────────────────────────────────────────────────────────
# OpenClaw - Script de Inicialização e Configuração
# ────────────────────────────────────────────────────────────────
#
# Este script auxilia na configuração inicial do ambiente OpenClaw:
#   1. Criação de diretórios necessários
#   2. Configuração de variáveis de ambiente
#   3. Gerenciamento de certificados SSL
#   4. Validação de dependências
#
# ────────────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/logs/init.log"

# ────────────────────────────────────────────────────────────────
# Funções de utilidade
# ────────────────────────────────────────────────────────────────

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "${LOG_FILE}" >&2
}

check_installed() {
  local cmd=$1
  if ! command -v "$cmd" &> /dev/null; then
    error "Comando '$cmd' não encontrado. Por favor, instale-o primeiro."
    return 1
  fi
  return 0
}

# ────────────────────────────────────────────────────────────────
# Verificação de dependências
# ────────────────────────────────────────────────────────────────

log "Verificando dependências..."

check_installed "docker" || {
  echo "Docker não está instalado. Por favor, instale-o antes de continuar."
  exit 1
}

check_installed "docker-compose" || {
  echo "Docker Compose não está instalado. Por favor, instale-o antes de continuar."
  exit 1
}

check_installed "git" || {
  echo "Git não está instalado. Por favor, instale-o antes de continuar."
  exit 1
}

# ────────────────────────────────────────────────────────────────
# Criar diretórios
# ────────────────────────────────────────────────────────────────

log "Criando diretórios necessários..."

mkdir -p "${SCRIPT_DIR}/data/.openclaw"
mkdir -p "${SCRIPT_DIR}/logs"
mkdir -p "${SCRIPT_DIR}/nginx/conf.d"
mkdir -p "${SCRIPT_DIR}/nginx/ssl"
mkdir -p "${SCRIPT_DIR}/nginx/logs"
mkdir -p "${SCRIPT_DIR}/ollama_data"
mkdir -p "${SCRIPT_DIR}/hermes_data"

# ────────────────────────────────────────────────────────────────
# Configurar variáveis de ambiente
# ───────────────────────────────────────────────────

log "Configurando variáveis de ambiente..."

# Criar arquivo .env se não existir
if [ ! -f "${SCRIPT_DIR}/.env" ]; then
  cat > "${SCRIPT_DIR}/.env" << 'EOF'
# ────────────────────────────────────────────────────────────────
# OpenClaw - Configuração de Ambiente
# ────────────────────────────────────────────────────────────────
# Copie este arquivo para .env.local e preencha com seus valores
# ────────────────────────────────────────────────────────────────

# Versões
OPENCLAW_VERSION=latest
NGINX_VERSION=1.27-alpine
OLLAMA_VERSION=latest

# Chaves de API (substitua pelos seus valores)
# GOOGLE_AI_KEY=
# GROQ_API_KEY=
# BRAVE_API_KEY=
# OPENROUTER_API_KEY=
# MOONSHOT_API_KEY=

# Ollama
OLLAMA_API_BASE=http://ollama:11434
OLLAMA_API_KEY=ollama-local

# OpenClaw
OPENCLAW_HOME=/home/openclaw
OPENCLAW_MODEL=ollama/qwen3.5
OPENCLAW_GATEWAY_TOKEN=
OPENCLAW_GATEWAY_PASSWORD=
OPENCLAW_PORT=18790
GATEWAY_BIND=0.0.0.0

# Telegram (opcional)
# TELEGRAM_BOT_TOKEN=

# NVAPI (opcional)
# NVAPI_API_KEY=

# Multi-agent
MULTIAGENT_MODE=enabled
AGENT_ISOLATION=workspace
ROUTING_STRATEGY=skill-based
LOG_LEVEL=info
TZ=America/Sao_Paulo

# Obsidian
OBSIDIAN_VAULT_PATH=/home/openclaw/obsidian
VAULT_ROOT=/home/openclaw/obsidian/Knowledge
EOF

  log "Arquivo .env criado com valores padrão."
  log "Por favor, preencha .env.local com suas chaves de API."
  log "Mova .env para .env.local e adicione suas configurações."
else
  log "Arquivo .env já existe. Usando configurações existentes."
fi

# ────────────────────────────────────────────────────────────────
# Configurar certificados SSL (opcional)
# ────────────────────────────────────────────────────────────────

log "Configurando certificados SSL (se aplicável)..."

if [ -d "${SCRIPT_DIR}/nginx/ssl" ] && [ -z "$(ls -A ${SCRIPT_DIR}/nginx/ssl 2>/dev/null)" ]; then
  log "Certificados SSL não encontrados no diretório /nginx/ssl/"
  log "Você pode adicionar certificados aqui manualmente ou usar:"
  log "  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\"
  log "    -keyout ssl/fullchain.pem \\"
  log "    -out ssl/fullchain.pem \\"
  log "    -subj '/C=BR/ST=SP/L=Sao Paulo/O=OpenClaw/CN=localhost' \\"
  log "    -addext subjectAltName=DNS:localhost,DNS:openclaw.local"
else
  log "Certificados SSL já existem ou não são necessários."
fi

# ────────────────────────────────────────────────────────────────
# Verificar volumes de Obsidian
# ────────────────────────────────────────────────────────────────

OBSIDIAN_VAULT="${SCRIPT_DIR}/obsidian/OpenClaw"

if [ -d "${OBSIDIAN_VAULT}" ] && [ -z "$(ls -A ${OBSIDIAN_VAULT} 2>/dev/null)" ]; then
  log "Vault de Obsidian não tem conteúdo. Você pode:"
  log "  1. Copiar seu vault existente para: ${OBSIDIAN_VAULT}"
  log "  2. Ou deixar o container criar um novo vault"
else
  log "Vault de Obsidian configurado em: ${OBSIDIAN_VAULT}"
fi

# ────────────────────────────────────────────────────────────────
# Verificar status de containers
# ────────────────────────────────────────────────────────────────

log "Verificando status dos containers..."

docker ps -a --filter "name=openclaw" --format "{{.Names}}" | grep -q "openclaw" || {
  log "Conteiner 'openclaw' não está rodando. Iniciando..."
  docker-compose up -d
}

# ────────────────────────────────────────────────────────────────
# Finalização
# ────────────────────────────────────────────────────────────────

log "Inicialização concluída com sucesso!"
log ""
log "Próximos passos:"
log "  1. Configure .env.local com suas chaves de API"
log "  2. Adicione certificados SSL em nginx/ssl/ se necessário"
log "  3. Copie seu vault de Obsidian para: ${OBSIDIAN_VAULT}"
log "  4. Execute: docker-compose pull para atualizar as imagens"
log "  5. Execute: docker-compose up -d para reiniciar os containers"
log ""
log "Logs disponíveis em: ${LOG_FILE}"
log "Dashboard do OpenClaw: http://localhost:18790"
log "Dashboard do Nginx: http://localhost"
log ""

exit 0
