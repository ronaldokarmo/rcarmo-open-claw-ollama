#!/bin/bash
# ────────────────────────────────
# OpenClaw - Script de Startup
# ────────────────────────────────
# Usage: ./start.sh [--reset|--config|--status]
# ────────────────────────────────

# Configurações
CONTAINER_NAME="openclaw"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"
LOGIC_PATH="$PROJECT_ROOT/data"
WORKSPACE_PATH="$PROJECT_ROOT/.openclaw/workspace"
LOG_DIR="$PROJECT_ROOT/logs"
CONFIG_PATH="$PROJECT_ROOT/config"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurar PS1 para terminal
export PS1="\e[36;1m\${PROJECT_NAME}:\u@openclaw \e[33m\w\e[0m \$ "

# Funções de log
log_error() {
    echo -e "${RED}❌ [ERROR]${NC} $1"
}

log_info() {
    echo -e "${GREEN}✓ [INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠ [WARN]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ [OK]${NC} $1"
}

log_config() {
    echo -e "${BLUE}[CONFIG]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Funções principais
setup_environment() {
    log_step "Configurando ambiente..."

    # Criar diretórios
    mkdir -p "$LOGIC_PATH"/agents/{workspace,cache}
    mkdir -p "$LOGIC_PATH"/data/{config,database,logs}
    mkdir -p "$LOGIC_PATH"/temp
    mkdir -p "$LOGIC_PATH"/workspace
    mkdir -p "$LOGIC_PATH"/output
    mkdir -p "$LOGIC_PATH"/uploads
    mkdir -p "$LOGIC_PATH"/backups

    # Criar diretórios do container
    mkdir -p "/workspace"
    mkdir -p "/app/logs"
    mkdir -p "/data"
    mkdir -p "/cache"
    mkdir -p "/workspace"

    # Criar arquivos de configuração
    cat > "/workspace/.dockerenv" <<'EOF'
# OpenClaw Docker Environment
# Auto-created on container startup
EOF

    cat > "/app/.dockerenv" <<'EOF'
# OpenClaw Docker Application
# Auto-created on container startup
EOF

    log_info "Ambiente configurado"
}

setup_workspace() {
    local workspace_name="${1:-}"

    if [ -z "$workspace_name" ]; then
        # Criar workspace por padrão
        log_step "Criando workspace padrão..."

        # Criar workspace principal
        mkdir -p "$WORKSPACE_PATH"

        # Criar arquivo de workspace
        cat > "$WORKSPACE_PATH/.workspace" <<'EOF'
# OpenClaw Workspace
# Principal workspace do container
EOF

        log_info "Workspace padrão criado"
        return 0
    fi

    # Criar workspace específico
    local workspace_path="$WORKSPACE_PATH/$workspace_name"

    if [ ! -d "$workspace_path" ]; then
        mkdir -p "$workspace_path"

        # Criar arquivo do workspace
        cat > "$workspace_path/.workspace" <<EOF
# OpenClaw Workspace: $workspace_name
# Criado automaticamente
EOF

        log_info "Workspace '$workspace_name' criado em: $workspace_path"
    else
        log_info "Workspace '$workspace_name' já existe"
    fi

    # Criar diretório de cache para o workspace
    local cache_path="$WORKSPACE_PATH/$workspace_name/cache"
    if [ ! -d "$cache_path" ]; then
        mkdir -p "$cache_path"
    fi

    # Criar arquivo de estado do workspace
    cat > "$workspace_path/.state" <<EOF
# OpenClaw Workspace State
# Atualizado automaticamente
EOF

    log_success "Workspace configurado: $workspace_name"
}

validate_config() {
    log_step "Validando configuração..."

    # Verificar diretórios
    for dir in "$LOGIC_PATH" "$LOGIC_PATH/data" "$LOGIC_PATH/temp" "$WORKSPACE_PATH"; do
        if [ -d "$dir" ]; then
            echo "  ✓ $dir"
        else
            log_error "Diretório ausente: $dir"
            return 1
        fi
    done

    # Verificar arquivos de configuração
    if [ -f "$PROJECT_ROOT/docker-compose.yml" ]; then
        echo "  ✓ docker-compose.yml"
    else
        log_error "docker-compose.yml não encontrado"
        return 1
    fi

    log_success "Configuração válida"
    return 0
}

backup_workspace() {
    local workspace_name="${1:-}"
    local backup_dir="${2:-$LOGIC_PATH/backups}"

    if [ -z "$workspace_name" ]; then
        # Backup de todos os workspaces
        log_step "Fazendo backup de workspaces..."
    else
        # Backup específico
        log_step "Fazendo backup de: $workspace_name"
    fi

    # Criar diretório de backup
    mkdir -p "$backup_dir"

    # Definir timestamp
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="${workspace_name:-all}_${timestamp}"
    local backup_path="$backup_dir/$backup_name"

    if [ -z "$workspace_name" ]; then
        # Backup de todos
        cp -r "$WORKSPACE_PATH"/* "$backup_path"/ 2>/dev/null || true
        cp -r "$LOGIC_PATH"/workspace/* "$backup_path"/ 2>/dev/null || true
    else
        # Backup específico
        local workspace_path="$WORKSPACE_PATH/$workspace_name"
        if [ -d "$workspace_path" ]; then
            cp -r "$workspace_path" "$backup_path/"
        fi
    fi

    # Criar arquivo de manifestação do backup
    local manifest="$backup_path/MANIFEST.md"
    cat > "$manifest" <<EOF
# OpenClaw Backup Manifest
# Timestamp: $timestamp
# Backup de: $workspace_name

## Conteúdo
$(find "$backup_path" -type f 2>/dev/null | sort)

## Tamanho
$(du -sh "$backup_path" 2>/dev/null | cut -f1)

## Status
Backup concluído com sucesso
EOF

    log_success "Backup criado: $backup_path"
    echo "  Tamanho: $(du -h "$backup_path" | cut -f1)"
}

restore_workspace() {
    local backup_path="$1"

    if [ ! -d "$backup_path" ]; then
        log_error "Backup não encontrado: $backup_path"
        return 1
    fi

    log_step "Restaurando workspace de: $backup_path"

    # Definir timestamp atual
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local workspace_name="workspace_restore_${timestamp}"
    local workspace_path="$WORKSPACE_PATH/$workspace_name"

    # Restaurar backup
    mkdir -p "$workspace_path"
    cp -r "$backup_path"/* "$workspace_path"/ 2>/dev/null || true

    # Criar arquivo de restauração
    cat > "$workspace_path/.restored" <<EOF
# OpenClaw Workspace Restored
# Restaurado de: $backup_path
# Timestamp: $timestamp
EOF

    log_success "Workspace restaurado em: $workspace_path"
}

delete_workspace() {
    local workspace_name="$1"

    if [ -z "$workspace_name" ]; then
        log_error "Nome do workspace não especificado"
        echo "Uso: $0 delete <nome-do-workspace>"
        return 1
    fi

    local workspace_path="$WORKSPACE_PATH/$workspace_name"

    if [ -d "$workspace_path" ]; then
        local confirm=0

        if [ -t 0 ]; then
            read -p "Tem certeza que deseja apagar '$workspace_name'? (y/n): " confirm
        else
            confirm=1
        fi

        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ] || [ "$confirm" = "1" ]; then
            rm -rf "$workspace_path"
            log_success "Workspace '$workspace_name' apagado"
            return 0
        else
            log_warn "Apagamento cancelado"
            return 1
        fi
    else
        log_warn "Workspace '$workspace_name' não encontrado"
        return 1
    fi
}

list_workspaces() {
    log_step "Listando workspaces..."
    echo ""

    if [ -d "$WORKSPACE_PATH" ]; then
        echo "Workspaces em execução:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        local count=0
        for dir in "$WORKSPACE_PATH"/*/; do
            if [ -d "$dir" ]; then
                local name=$(basename "$dir")
                local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
                local created=$(stat -c '%y' "$dir" 2>/dev/null | cut -d',' -f2 | cut -d'.' -f1)

                echo ""
                echo "  📁 $name"
                echo "     Path: $dir"
                echo "     Tamanho: $size"
                echo "     Criado: $created"

                # Mostrar estado se arquivo existir
                if [ -f "$dir/.state" ]; then
                    echo "     Status: ✓ Ativo"
                fi

                # Mostrar cache se existir
                if [ -d "$dir/cache" ]; then
                    local cache_size=$(du -sh "$dir/cache" 2>/dev/null | cut -f1)
                    if [ "$cache_size" != "4.0K" ]; then
                        echo "     Cache: ✓ ($cache_size)"
                    fi
                fi

                count=$((count + 1))
            fi
        done

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Total de workspaces: $count"
    else
        echo "Nenhum workspace encontrado"
        echo "O diretório '$WORKSPACE_PATH' não existe"
    fi

    echo ""
}

create_new_workspace() {
    local name="${1:-}"

    if [ -z "$name" ]; then
        echo "📝 Digite o nome do workspace:"
        read name
    fi

    # Validar nome
    if [ -z "$name" ] || [ "$name" = "$name"@* ]; then
        log_error "Nome inválido"
        return 1
    fi

    # Verificar se já existe
    if [ -d "$WORKSPACE_PATH/$name" ]; then
        log_warn "Workspace '$name' já existe"
        return 1
    fi

    # Criar workspace
    mkdir -p "$WORKSPACE_PATH/$name"

    # Criar arquivos do workspace
    cat > "$WORKSPACE_PATH/$name/.workspace" <<EOF
# OpenClaw Workspace
# Nome: $name
# Criado automaticamente
EOF

    # Criar diretório de cache
    mkdir -p "$WORKSPACE_PATH/$name/cache"

    # Criar arquivo de estado
    cat > "$WORKSPACE_PATH/$name/.state" <<EOF
# OpenClaw Workspace State
# Nome: $name
# Status: created
EOF

    # Criar diretório de logs do workspace
    mkdir -p "$WORKSPACE_PATH/$name/logs"

    # Criar arquivo de configuração
    cat > "$WORKSPACE_PATH/$name/.config" <<EOF
# OpenClaw Workspace Configuration
# Nome: $name
EOF

    log_success "Workspace '$name' criado"
    echo "  Path: $WORKSPACE_PATH/$name"
    echo "  Cache: $WORKSPACE_PATH/$name/cache"
    echo "  Logs: $WORKSPACE_PATH/$name/logs"
}

backup_current_workspace() {
    if [ -d "$WORKSPACE_PATH" ]; then
        # Pegar workspace mais recente
        local workspace_path=$(ls -dt "$WORKSPACE_PATH"/*/ 2>/dev/null | head -n1)
        local workspace_name=$(basename "$workspace_path")

        if [ -n "$workspace_name" ]; then
            backup_workspace "$workspace_name"
        fi
    fi
}

backup_all_workspaces() {
    if [ -d "$WORKSPACE_PATH" ]; then
        # Criar backup de todos os workspaces
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_name="all_workspaces_${timestamp}"
        local backup_path="$LOGIC_PATH/backups/$backup_name"

        mkdir -p "$backup_path"

        # Copiar todos os workspaces
        cp -r "$WORKSPACE_PATH"/* "$backup_path"/ 2>/dev/null || true

        # Criar manifest
        cat > "$backup_path/MANIFEST.md" <<EOF
# OpenClaw Backup Manifest
# Timestamp: $timestamp
# Backup de todos os workspaces

## Workspaces incluídos
$(find "$backup_path" -type d -name "*.workspace" -exec dirname {} \; | sort)

## Tamanho total
$(du -sh "$backup_path" 2>/dev/null | cut -f1)

## Status
Backup completo concluído
EOF

        log_success "Backup de todos os workspaces criado: $backup_path"
    fi
}

start_container() {
    log_step "Iniciando container..."

    # Verificar se já está rodando
    if docker ps --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
        log_warn "Container já está rodando"
        return 1
    fi

    # Verificar se está parado
    if docker ps -a --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
        log_step "Container parado - reiniciando..."
        docker start "$CONTAINER_NAME" 2>/dev/null || true
    fi

    # Iniciar container
    docker-compose up -d 2>/dev/null || docker start "$CONTAINER_NAME" 2>/dev/null || true

    # Esperar para garantir que está rodando
    sleep 2

    # Verificar status
    if docker ps --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
        log_success "Container iniciado"
        echo ""
        echo "Container: $CONTAINER_NAME"
        echo "Status: ✓ Rodando"
        echo ""
        echo "Acesse:"
        echo "  Web UI: http://localhost:3000"
        echo "  Logs:   $LOG_DIR/$CONTAINER_NAME.log"
        echo ""
        return 0
    else
        log_error "Falha ao iniciar container"
        return 1
    fi
}

stop_container() {
    log_step "Parando container..."

    if docker ps --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
        docker-compose down 2>/dev/null || docker stop "$CONTAINER_NAME" 2>/dev/null || true
        log_success "Container parado"
        return 0
    else
        log_warn "Container não está rodando"
        return 1
    fi
}

reset_container() {
    log_step "Reiniciando container completo..."

    # Parar e remover container atual
    stop_container 2>/dev/null || true

    # Remover imagem se existir
    docker-compose down -r 2>/dev/null || true

    # Reiniciar
    start_container
}

show_help() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║         OpenClaw - Script de Startup                       ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║  Uso: $0 [opções]                                          ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║  Comandos:                                                 ║"
    echo "║    start          Iniciar o container                      ║"
    echo "║    stop           Parar o container                        ║"
    echo "║    reset          Reiniciar o container completo            ║"
    echo "║    status         Verificar status do container            ║"
    echo "║    setup          Configurar ambiente inicial              ║"
    echo "║    validate       Validar configuração                      ║"
    echo "║    list           Listar workspaces em execução            ║"
    echo "║    create <name>  Criar novo workspace                     ║"
    echo "║    backup [name]  Fazer backup de workspace                ║"
    echo "║    restore <name> Restaurar workspace de backup            ║"
    echo "║    delete <name>  Apagar workspace                          ║"
    echo "║    config         Ver/gerar arquivos de configuração        ║"
    echo "║    logs           Ver logs do container                    ║"
    echo "║    watch          Monitorar em tempo real                   ║"
    echo "║    watch <name>   Monitorar workspace específico            ║"
    echo "║    monitor        Executar script de monitoramento          ║"
    echo "║    monitor <opts> Passar opções ao monitor                 ║"
    echo "║    backup-all     Fazer backup de todos os workspaces      ║"
    echo "║    help           Mostrar este menu                         ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""

    echo "Exemplos:"
    echo "  $0                     - Mostrar menu interativo"
    echo "  $0 start               - Iniciar container"
    echo "  $0 reset               - Reiniciar container completo"
    echo "  $0 create novo-ws      - Criar workspace 'novo-ws'"
    echo "  $0 backup              - Backup do workspace atual"
    echo "  $0 backup-all          - Backup de todos os workspaces"
    echo "  $0 monitor --watch     - Monitorar em tempo real"
    echo ""
    echo "Para usar o monitor:"
    echo "  $0 monitor             - Menu interativo"
    echo "  $0 monitor --watch     - Monitorar em tempo real"
    echo "  $0 monitor --tail 100  - Últimas 100 linhas"
    echo "  $0 monitor --stats     - Estatísticas"
    echo "  $0 monitor --help      - Ajuda do monitor"
    echo ""
}

# Parsear argumentos
COMMAND=""
ARGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --version|-v)
            echo "OpenClaw Startup Script v1.0"
            exit 0
            ;;
        *)
            COMMAND="$1"
            shift
            ARGS="$@"
            break
            ;;
    esac
done

# Executar comando
case "$COMMAND" in
    start)
        start_container
        ;;
    stop)
        stop_container
        ;;
    reset)
        reset_container
        ;;
    status)
        if docker ps --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
            echo "Container: ✓ Rodando"
            echo "Status: $(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)"
            echo ""
            echo "Web UI: http://localhost:3000"
        else
            echo "Container: ❌ Parado"
            echo "Para iniciar: $0 start"
        fi
        ;;
    setup)
        setup_environment
        setup_workspace
        validate_config
        ;;
    validate)
        validate_config
        ;;
    list)
        list_workspaces
        ;;
    create)
        create_new_workspace "${ARGS:-}"
        ;;
    backup)
        backup_workspace "${ARGS:-}"
        ;;
    backup-all)
        backup_all_workspaces
        ;;
    restore)
        restore_workspace "${ARGS:-}"
        ;;
    delete)
        delete_workspace "${ARGS:-}"
        ;;
    config)
        echo "Arquivos de configuração:"
        echo "  $CONFIG_PATH"
        echo "  docker-compose.yml"
        echo ""
        ls -la "$CONFIG_PATH" 2>/dev/null || true
        ;;
    logs)
        tail_logs 50
        ;;
    watch)
        if [ -n "${ARGS:-}" ]; then
            # Passar para monitor.sh
            ./.openclaw/scripts/monitor.sh "$ARGS"
        else
            watch_logs
        fi
        ;;
    monitor)
        if [ -f "./.openclaw/scripts/monitor.sh" ]; then
            ./.openclaw/scripts/monitor.sh "$ARGS"
        else
            watch_logs
        fi
        ;;
    *)
        show_help
        ;;
esac

exit 0
