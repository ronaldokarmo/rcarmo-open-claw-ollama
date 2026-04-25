#!/bin/bash
# ─────────────────────────────────────────────────────────────────────
# Entrypoint Script Otimizado
# ─────────────────────────────────────────────────────────────────────
# Funções:
#   1. Configurar ambiente
#   2. Verificar dependências
#   3. Iniciar containers
#   4. Configurar saúde e monitoramento
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

# Cores para saída legível
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Títulos
log_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_warn() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
}

# Configurar variáveis de ambiente padrão
setup_environment() {
  log_info "Configurando ambiente..."

  # Definir diretórios padrão
  export OPENCLAW_HOME="${OPENCLAW_HOME:-/home/openclaw}"
  export DATA_DIR="${OPENCLAW_HOME}/data"
  export CACHE_DIR="${OPENCLAW_HOME}/cache"
  export LOG_DIR="${OPENCLAW_HOME}/logs"

  # Criar diretórios necessários
  mkdir -p "$DATA_DIR"
  mkdir -p "$CACHE_DIR"
  mkdir -p "$LOG_DIR"

  log_success "Diretórios criados"
}

# Verificar dependências
check_dependencies() {
  log_info "Verificando dependências..."

  local missing=0

  # Verificar Node.js
  if ! command -v node &> /dev/null; then
    log_error "Node.js não encontrado"
    missing=1
  else
    log_success "Node.js $(node --version)"
  fi

  # Verificar Docker
  if ! command -v docker &> /dev/null; then
    log_error "Docker não encontrado"
    missing=1
  else
    log_success "Docker $(docker --version)"
  fi

  # Verificar Docker Compose
  if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose não encontrado"
    missing=1
  else
    log_success "Docker Compose $(docker-compose --version)"
  fi

  return $missing
}

# Iniciar containers
start_containers() {
  log_info "Iniciando containers..."

  # Construir imagem
  log_info "Construindo imagem OpenClaw..."
  docker build --target app \
    -t openclaw:latest \
    -f Dockerfile \
    .
  log_success "Imagem construída"

  # Iniciar com docker-compose
  log_info "Iniciando containers..."
  docker-compose up -d
  log_success "Containers iniciados"
}

# Configurar saúde e monitoramento
setup_healthchecks() {
  log_info "Configurando saúde e monitoramento..."

  # Verificar saúde
  sleep 5
  if docker-compose ps | grep -q "Up"; then
    log_success "Saúde verificada"
  else
    log_warn "Saúde não verificada"
  fi
}

# Configurar logs
setup_logging() {
  log_info "Configurando logs..."

  # Garantir que os logs estão configurados
  cat > /etc/rsyslog.d/99-openclaw.conf << 'EOF'
# Logs específicos para OpenClaw
:programname, i, isequal "name, 'openclaw'.*/" /var/log/openclaw/
:msg, contains, "openclaw" /var/log/openclaw/
EOF

  log_success "Logs configurados"
}

# Principais
main() {
  echo "=========================================="
  echo "  Entrypoint Script - OpenClaw"
  echo "=========================================="
  echo ""

  # Verificar se é container
  if [ -f /.dockerenv ]; then
    log_info "Executando em ambiente Docker"
  fi

  # Configurar ambiente
  setup_environment
  echo ""

  # Verificar dependências
  if ! check_dependencies; then
    log_error "Dependências ausentes. Parando."
    exit 1
  fi
  echo ""

  # Iniciar containers
  start_containers
  echo ""

  # Configurar saúde
  setup_healthchecks
  echo ""

  # Configurar logs
  setup_logging
  echo ""

  log_success "Inicialização concluída com sucesso!"
  echo "=========================================="
}

# Executar
main "$@"
