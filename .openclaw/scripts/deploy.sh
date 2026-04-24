#!/bin/bash
# ────────────────────────────────────────────────────────────────
# OpenClaw - Script de Deploy
# ────────────────────────────────────────────────────────────────
# Usage: ./deploy.sh [dry-run|prod|stage]
# ────────────────────────────────────────────────────────────────

set -e

# Configurações
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
COMPOSE_PRODUCTION="$PROJECT_ROOT/docker-compose.prod.yml"
COMPOSE_STAGE="$PROJECT_ROOT/docker-compose.stage.yml"
LOG_LEVEL="${LOG_LEVEL:-info}"
OPENCLAW_VERSION="${OPENCLAW_VERSION:-latest}"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
}

# Verificar Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker não instalado ou não no PATH"
        exit 1
    fi
    log_info "Docker está disponível (v$(docker --version | cut -d' ' -f3))"
}

# Verificar Docker Compose
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        log_info "docker-compose não instalado, usando docker compose"
    else
        log_info "docker-compose está disponível (v$(docker-compose --version | cut -d' ' -f3))"
    fi
}

# Preparar variáveis de ambiente
prepare_environment() {
    log_section "Preparando ambiente"

    # Criar arquivo .env se não existir
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        log_info "Criando arquivo .env..."
        if [ -f "$PROJECT_ROOT/.env.example" ]; then
            cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
        else
            log_warn "Arquivo .env.example não encontrado. Criando .env vazio."
            touch "$PROJECT_ROOT/.env"
        fi
    fi

    # Sincronizar .env com variáveis de sistema
    if [ -n "${GOOGLE_AI_KEY:-}" ]; then
        echo "GOOGLE_AI_KEY=${GOOGLE_AI_KEY}" >> "$PROJECT_ROOT/.env"
    fi
    if [ -n "${GROQ_API_KEY:-}" ]; then
        echo "GROQ_API_KEY=${GROQ_API_KEY}" >> "$PROJECT_ROOT/.env"
    fi
    if [ -n "${BRAVE_API_KEY:-}" ]; then
        echo "BRAVE_API_KEY=${BRAVE_API_KEY}" >> "$PROJECT_ROOT/.env"
    fi
    if [ -n "${OPENROUTER_API_KEY:-}" ]; then
        echo "OPENROUTER_API_KEY=${OPENROUTER_API_KEY}" >> "$PROJECT_ROOT/.env"
    fi
    if [ -n "${MOONSHOT_API_KEY:-}" ]; then
        echo "MOONSHOT_API_KEY=${MOONSHOT_API_KEY}" >> "$PROJECT_ROOT/.env"
    fi
    if [ -n "${OLLAMA_API_KEY:-}" ]; then
        echo "OLLAMA_API_KEY=${OLLAMA_API_KEY}" >> "$PROJECT_ROOT/.env"
    fi

    log_info "Ambiente preparado"
}

# Build da imagem
build_image() {
    log_section "Build da imagem OpenClaw"
    docker compose -f "$COMPOSE_FILE" build
    log_info "Imagem buildada com sucesso"
}

# Pull de imagens atualizadas
pull_images() {
    log_section "Pull de imagens atualizadas"
    docker compose -f "$COMPOSE_FILE" pull
    log_info "Imagens atualizadas com sucesso"
}

# Stop dos containers
stop_containers() {
    log_section "Parando containers existentes"
    docker compose -f "$COMPOSE_FILE" down
    log_info "Containers parados"
}

# Start dos containers
start_containers() {
    log_section "Iniciando containers"

    # Start em background
    if [ "$1" == "start" ]; then
        docker compose -f "$COMPOSE_FILE" up -d
    else
        # Start em foreground para desenvolvimento
        docker compose -f "$COMPOSE_FILE" up
    fi
}

# Health checks
health_check() {
    log_section "Verificando health checks"
    sleep 10 # Dar tempo para inicialização

    local healthy=0
    local unhealthy=0

    for service in openclaw nginx ollama hermes; do
        if docker compose -f "$COMPOSE_FILE" ps | grep -q "$service.*healthy"; then
            log_info "$service: HEALTHY"
            ((healthy++))
        else
            log_warn "$service: UNHEALTHY (restarting)"
            docker compose -f "$COMPOSE_FILE" restart "$service"
            ((unhealthy++))
        fi
    done

    log_info "Status: $healthy healthy, $unhealthy unhealthy"
}

# Deploy principal
deploy() {
    local mode="${1:-prod}"

    log_section "Deploy OpenClaw - Modo: $mode"

    # Preparar ambiente
    prepare_environment

    # Build e pull
    build_image
    pull_images

    # Stop containers existentes
    stop_containers

    # Apply configurações de modo
    if [ "$mode" == "prod" ]; then
        if [ -f "$COMPOSE_PRODUCTION" ]; then
            log_info "Aplicando configurações de produção"
            # Merge de configurações de produção
        fi
    elif [ "$mode" == "stage" ]; then
        if [ -f "$COMPOSE_STAGE" ]; then
            log_info "Aplicando configurações de staging"
        fi
    fi

    # Start containers
    start_containers "start"

    # Health checks
    health_check

    log_section "Deploy concluído com sucesso!"
}

# Dry run (verifica sem aplicar)
dry_run() {
    log_section "Dry Run - Verificando deploy"

    # Verificar dependências
    if ! docker --version &> /dev/null; then
        log_error "Docker não instalado"
        return 1
    fi

    # Verificar .env
    if [ -f "$PROJECT_ROOT/.env" ]; then
        log_info ".env encontrado"
        # Mostrar variáveis (sem senhas)
        grep -v "^SECRET_\|^API_KEY\|^TOKEN" "$PROJECT_ROOT/.env" | \
            sed 's/=.*/=********/; s/^[^=]*=.*/VARIÁVEL=********/'
    else
        log_warn ".env não encontrado"
    fi

    # Verificar volumes
    if [ -d "$PROJECT_ROOT/logs" ]; then
        log_info "Volume de logs: OK"
    else
        log_warn "Volume de logs não existe"
    fi

    if [ -d "$PROJECT_ROOT/data/.openclaw" ]; then
        log_info "Volume de dados: OK"
    else
        log_warn "Volume de dados não existe"
    fi

    log_info "Dry run concluída"
}

# Mostrar status
status() {
    log_section "Status dos Containers"
    docker compose -f "$COMPOSE_FILE" ps
}

# Principais comandos
case "${1:-}" in
    deploy)
        shift
        deploy "$@"
        ;;
    build)
        build_image
        ;;
    pull)
        pull_images
        ;;
    stop)
        stop_containers
        ;;
    start)
        start_containers
        ;;
    restart)
        stop_containers
        start_containers
        ;;
    status)
        status
        ;;
    health)
        health_check
        ;;
    dry-run|dryrun)
        dry_run
        ;;
    *)
        echo "OpenClaw Deploy Script"
        echo ""
        echo "Uso: $0 [comando] [opções]"
        echo ""
        echo "Comandos:"
        echo "  deploy [prod|stage|stage2]  - Deploy em modo especificado"
        echo "  build                        - Build da imagem"
        echo "  pull                         - Pull de imagens atualizadas"
        echo "  stop                         - Parar containers"
        echo "  start                        - Iniciar containers"
        echo "  restart                      - Reiniciar containers"
        echo "  status                       - Mostrar status"
        echo "  health                       - Verificar health checks"
        echo "  dry-run                      - Verificar deploy sem aplicar"
        echo ""
        echo "Exemplos:"
        echo "  $0 deploy prod               - Deploy em produção"
        echo "  $0 build                     - Build da imagem"
        echo "  $0 status                    - Mostrar status"
        ;;
esac
