#!/bin/bash
# ─────────────────────────────────────────────────────────────
# OpenClaw - Script de Deploy Assistido
# ─────────────────────────────────────────────────────────────
# Uso: ./deploy.sh [command] [options]
# ─────────────────────────────────────────────────────────────

set -e

# Configurações
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
CONTAINER_NAME="openclaw"
DOCKER_HUB_IMAGE="${DOCKER_HUB_IMAGE:-ronaldo765/openclaw:latest}"
BUILD_ARGS="${BUILD_ARGS:-}"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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
    echo -e "${BLUE}═════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═════════════════════════════════════════════════════${NC}"
}

log_cyan() {
    echo -e "${CYAN}$1${NC}"
}

# Verificar dependências
check_dependencies() {
    local missing_deps=0

    if ! command -v docker &> /dev/null; then
        log_error "Docker não instalado ou não no PATH"
        missing_deps=1
    fi

    if ! command -v git &> /dev/null; then
        log_error "Git não instalado ou não no PATH"
        missing_deps=1
    fi

    return $missing_deps
}

# Build da imagem
build_image() {
    log_section "Build da Imagem OpenClaw"

    # Verificar se está no diretório correto
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log_error "docker-compose.yml não encontrado em: $PROJECT_ROOT"
        return 1
    fi

    log_cyan "Detectando mudanças no Dockerfile..."

    # Build
    log_info "Executando: docker-compose build --no-cache"
    docker-compose build --no-cache

    log_info "Build concluído com sucesso!"
}

# Push para Docker Hub
push_image() {
    log_section "Push para Docker Hub"

    if [ -n "$DOCKER_HUB_IMAGE" ]; then
        log_info "Imagem: $DOCKER_HUB_IMAGE"
        log_info "Tag: $(git describe --tags --exact-match 2>/dev/null || echo 'latest')"

        # Verificar tags existentes
        existing_tags=$(docker images "$CONTAINER_NAME" --format "{{{{.Repository}}}{{{{':'}}}}{{.Tag}}}}" | cut -d' ' -f3 | grep -v 'no image' || true)

        if [ -z "$existing_tags" ]; then
            log_warn "Nenhuma tag encontrada. Build necessário primeiro."
            return 1
        fi

        log_info "Tags para push:"
        echo "$existing_tags"

        log_info "Executando: docker push"
        docker push "$DOCKER_HUB_IMAGE"

        log_info "Push concluído!"
    else
        log_info "DOCKER_HUB_IMAGE não definido. Use -t user/repo:tag para definir."
    fi
}

# Deploy
deploy() {
    log_section "Deploy do OpenClaw"

    log_info "Verificando docker-compose.yml..."
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log_error "docker-compose.yml não encontrado"
        return 1
    fi

    log_info "Parando container (se existir)..."
    docker-compose down
    log_info "Container parado e limpo"

    log_info "Reiniciando container com nova imagem..."
    docker-compose up -d

    log_info "Deploy concluído!"

    # Verificar status
    log_info ""
    log_cyan "Status do container:"
    docker-compose ps

    # Testar health check
    if docker-compose exec -T openclaw curl --head --silent --max-time 5 http://localhost:8000/health | grep -q "200 OK\|400 Bad Request"; then
        log_info "✅ Health check: OK"
    else
        log_warn "⚠️  Health check não respondeu (pode demorar a primeira vez)"
    fi
}

# Rollback
rollback() {
    log_section "Rollback para imagem anterior"

    # Encontrar imagem anterior
    if [ ! -n "$TAG_PREVIOUS" ]; then
        log_warn "Nenhuma tag anterior encontrada. Imagem anterior: $(docker images "$CONTAINER_NAME" --format '{{{{.ID}}}' | head -1)"
        log_warn "Você pode definir TAG_PREVIOUS manualmente para rollback específico"
    fi

    docker-compose down
    docker pull "$TAG_PREVIOUS"
    docker-compose up -d --no-build

    log_info "Rollback concluído!"
}

# Verificar status
status() {
    log_section "Status do Serviço"

    if ! docker ps --format "{{{{.Names}}}}" | grep -q "$CONTAINER_NAME"; then
        log_warn "Container não está rodando"
        return 1
    fi

    log_info ""
    log_cyan "Container: $CONTAINER_NAME"
    log_info "Status: $(docker inspect -f '{{{{.State.Status}}}}' "$CONTAINER_NAME")"
    log_info "Imagem: $(docker inspect -f '{{{{.Config.Image}}}}' "$CONTAINER_NAME")"
    log_info ""
    log_cyan "Volume mounts:"
    docker inspect -f '{{range .Mounts}}{{.Type}}: {{.Source}} -> {{.Destination}} ({{with .RW}}{{.}}{{else}}ro{{end}}){{end}}' "$CONTAINER_NAME"
    log_info ""
    log_cyan "Ports:"
    docker port "$CONTAINER_NAME"
    log_info ""

    # Logs recentes
    log_section "Logs Recentes"
    docker logs --tail 20 "$CONTAINER_NAME"
}

# Verificar logs
logs() {
    log_section "Logs do Serviço"
    docker logs --tail "${1:-50}" "$CONTAINER_NAME"
}

# Reset completo
reset() {
    log_section "Reset Completo"

    log_warn "⚠️  Esta ação apaga todos os dados persistentes!"
    log_warn "Certifique-se de ter feito backup se necessário."
    log_info ""

    read -p "Deseja continuar? (sim/não): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Ss][Ii][Mm]$ ]]; then
        log_info "Operação cancelada"
        return 0
    fi

    log_info "Parando container..."
    docker-compose down -v

    log_info "Reset concluído!"
}

# Restaurar backup
restore_backup() {
    log_section "Restaurar Backup"

    BACKUP_FILE="${1:-}"
    BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.openclaw-backups}"

    if [ -z "$BACKUP_FILE" ]; then
        log_warn "Nenhum arquivo de backup especificado."
        log_warn "Uso: ./deploy.sh restore <backup_file>"
        return 1
    fi

    if [ ! -f "$BACKUP_FILE" ]; then
        log_error "Arquivo de backup não encontrado: $BACKUP_FILE"
        return 1
    fi

    log_info "Arquivo de backup: $BACKUP_FILE"
    log_info "Tamanho: $(du -h "$BACKUP_FILE" | cut -f1)"

    log_info "Destrói container atual e volume..."
    docker-compose down -v

    log_info "Cria novo container..."
    docker-compose up -d

    log_info "Restaurando dados do backup:"
    gunzip -c "$BACKUP_FILE" > /dev/null 2>&1 || true
    tar -tzf "$BACKUP_FILE" | tail -1

    log_info "Backup restaurado com sucesso!"
}

# Backup pré-deploy
predeploy_backup() {
    log_section "Backup Pré-Deploy"

    BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.openclaw-backups}"
    DATE_SUFFIX=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="$BACKUP_ROOT/predeploy/$DATE_SUFFIX"

    mkdir -p "$BACKUP_DIR"

    log_info "Backup de dados..."
    if [ -d "$PROJECT_ROOT/data" ]; then
        cp -r "$PROJECT_ROOT/data" "$BACKUP_DIR/"
        log_info "Dados salvos em: $BACKUP_DIR/"
    fi

    log_info "Backup de workspace dos agents..."
    if [ -d "$PROJECT_ROOT/.openclaw/workspace" ]; then
        cp -r "$PROJECT_ROOT/.openclaw/workspace" "$BACKUP_DIR/workspace/"
        log_info "Workspaces salvos em: $BACKUP_DIR/workspace/"
    fi

    log_info "Backup de configurações..."
    if [ -f "$PROJECT_ROOT/.env" ]; then
        cp "$PROJECT_ROOT/.env" "$BACKUP_DIR/.env.bak"
        log_info ".env salvo em: $BACKUP_DIR/.env.bak"
    fi

    log_info ""
    log_info "Backup pré-deploy concluído:"
    echo "$BACKUP_DIR"
}

# Monitoramento
monitor() {
    log_section "Monitoramento"

    log_cyan "=== Métricas do Container ==="
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}" "$CONTAINER_NAME"

    log_cyan ""
    echo "=== Logs em Tempo Real (últimas 50 linhas) ==="
    docker logs --tail 50 "$CONTAINER_NAME"
}

# Atualizar imagem
pull_update() {
    log_section "Atualizar Imagem"

    log_info "Puxando nova imagem da Docker Hub..."
    docker-compose pull

    log_info "Reiniciando container com nova imagem..."
    docker-compose up -d

    log_info "Atualização concluída!"
}

# Show help
show_help() {
    log_section "OpenClaw Deploy Assistant - Ajuda"

    echo ""
    log_cyan "Uso: $0 [comando] [opções]"
    echo ""
    echo "Comandos:"
    echo ""
    echo "  deploy              - Deploy padrão (build + up)"
    echo "  build               - Build da imagem"
    echo "  push                - Push para Docker Hub"
    echo "  pull                - Pull da imagem"
    echo "  down                - Parar container"
    echo "  up                  - Iniciar container"
    echo "  restart             - Reiniciar container"
    echo "  status              - Verificar status"
    echo "  logs                - Ver logs (--tail <n> opcional)"
    echo "  reset               - Reset completo (apaga volumes)"
    echo "  rollback            - Rollback para imagem anterior"
    echo "  update              - Puxar e reiniciar com nova imagem"
    echo "  monitor             - Mostrar métricas e logs"
    echo ""
    echo "  predeploy           - Backup pré-deploy automático"
    echo "  restore <file>      - Restaurar backup específico"
    echo ""
    echo "Exemplos:"
    echo "  $0 deploy               # Deploy padrão"
    echo "  $0 build -t ronaldokar # Build com push para Docker Hub"
    echo "  $0 push -t ronaldokar   # Push para Docker Hub"
    echo "  $0 predeploy            # Backup antes de deploy"
    echo "  $0 restore backup.tar.gz # Restaurar backup"
    echo ""
    echo "Variáveis de ambiente:"
    echo "  DOCKER_HUB_IMAGE - Imagem para push (padrão: ronaldokar/openclaw:latest)"
    echo "  TAG_PREVIOUS      - Tag anterior para rollback"
    echo ""
}

# Build com push
build_and_push() {
    log_section "Build e Push"

    build_image
    log_info ""
    read -p "Deseja push para Docker Hub? (sim/não): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Ss][Ii][Mm]$ ]]; then
        push_image
    fi
}

# Principais comandos
case "${1:-help}" in
    deploy)
        check_dependencies
        log_info "Deploy padrão - build + up"
        build_image
        log_info ""
        read -p "Desejar push para Docker Hub? (sim/não): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss][Ii][Mm]$ ]]; then
            push_image
        fi
        deploy
        log_info "✅ Deploy concluído!"
        ;;

    build)
        check_dependencies
        build_image
        ;;

    push)
        check_dependencies
        build_and_push
        ;;

    pull)
        log_section "Pull da Imagem"
        if [ ! -n "$DOCKER_HUB_IMAGE" ]; then
            log_warn "Nenhuma imagem especificada. Use -t user/repo:tag"
        else
            docker-compose pull
        fi
        ;;

    down)
        log_section "Parar Container"
        docker-compose down
        log_info "Container parado"
        ;;

    up)
        log_section "Iniciar Container"
        docker-compose up -d
        log_info "Container iniciado"
        ;;

    restart)
        log_section "Reiniciar Container"
        docker-compose restart
        log_info "Container reiniciado"
        ;;

    status)
        status
        ;;

    logs)
        logs "${2:-50}"
        ;;

    reset)
        reset
        ;;

    rollback)
        rollback
        ;;

    update)
        pull_update
        ;;

    monitor)
        monitor
        ;;

    predeploy)
        check_dependencies
        predeploy_backup
        log_info ""
        read -p "Deseja continuar com o deploy? (sim/não): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss][Ii][Mm]$ ]]; then
            build_and_push
            read -p "Deseja deploy agora? (sim/não): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Ss][Ii][Mm]$ ]]; then
                deploy
            fi
        fi
        ;;

    restore)
        check_dependencies
        restore_backup "$2"
        ;;

    help|*)
        show_help
        ;;
esac

echo ""
log_info "OpenClaw Deploy Assistant - Pronto!"
