#!/bin/bash
# ────────────────────────────────
# OpenClaw - Monitor de Saída
# ────────────────────────────────
# Usage: ./monitor.sh [--watch|--tail|--recent|--stats]
# ────────────────────────────────

# Configurações
CONTAINER_NAME="openclaw"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"
LOGIC_PATH="$PROJECT_ROOT/data"
WORKSPACE_PATH="$PROJECT_ROOT/.openclaw/workspace"
LOG_DIR="$PROJECT_ROOT/logs"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Funções principais
tail_logs() {
    local last_lines="${1:-50}"
    log_info "Mostrando últimas $last_lines linhas dos logs de todos os containers"
    echo ""
    docker logs --tail "$last_lines" 2>/dev/null | \
        grep -E "(DEBUG|INFO|WARN|ERROR|Exception)" | \
        grep -v "^$" | \
        awk -v proj="$PROJECT_NAME" '{
            if ($0 ~ /ERROR/) {
                color = "31m";
                tag = "ERROR";
            } else if ($0 ~ /WARN/) {
                color = "1;33m";
                tag = "WARN";
            } else if ($0 ~ /Exception/) {
                color = "1;31m";
                tag = "EXCEPTION";
            } else if ($0 ~ /Stack/) {
                color = "1;31m";
                tag = "STACK";
            } else {
                color = "0m";
                tag = "LOG";
            }
            printf color "[%s]" color "\e[0m %s\n", tag, $0
        }' || true
    echo ""
}

watch_logs() {
    log_info "Monitoramento em tempo real dos logs (Ctrl+C para parar)"
    echo ""
    echo "Pressione 'q' para sair ou digite 'last 100' para ver as últimas 100 linhas"
    echo ""
    docker logs --follow --tail 100 2>/dev/null | \
        grep -E "(DEBUG|INFO|WARN|ERROR|Exception)" | \
        grep -v "^$" | \
        awk -v proj="$PROJECT_NAME" '{
            if ($0 ~ /ERROR/) {
                print "\e[31m[ERROR]\e[0m " $0
            } else if ($0 ~ /WARN/) {
                print "\e[1;33m[WARN]\e[0m " $0
            } else if ($0 ~ /Exception/) {
                print "\e[1;31m[EXCEPTION]\e[0m " $0
            } else if ($0 ~ /Stack/) {
                print "\e[1;31m[STACK]\e[0m " $0
            } else {
                print $0
            }
        }'
}

recent_logs() {
    local lines="${1:-100}"
    log_info "Mostrando últimas $lines linhas dos logs"
    echo ""
    docker logs --tail "$lines" 2>/dev/null | \
        tail -n "$lines" | \
        grep -E "(DEBUG|INFO|WARN|ERROR|Exception)" | \
        grep -v "^$" || true
    echo ""
}

stats() {
    log_info "Estatísticas do container $CONTAINER_NAME"
    echo ""

    # Status do container
    if docker ps -a --format "{{.Status}}" 2>/dev/null | grep -q "$CONTAINER_NAME"; then
        echo "Status: ✅ Rodando"
        echo "Estado: $(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)"
    else
        echo "Status: ❌ Parado"
    fi

    echo ""

    # Uso de recursos
    echo "Uso de recursos:"

    if docker stats --no-stream --containers "$CONTAINER_NAME" 2>/dev/null; then
        echo ""
    fi

    # Espaço de disco
    echo ""
    echo "Espaço no diretório lógico:"
    if [ -d "$LOGIC_PATH" ]; then
        local size=$(du -sh "$LOGIC_PATH" 2>/dev/null | cut -f1)
        echo "  Total de dados: $size"
    fi

    # Workspaces ativos
    echo ""
    echo "Workspaces em execução:"
    if [ -d "$WORKSPACE_PATH" ]; then
        local count=$(ls -1d "$WORKSPACE_PATH"/* 2>/dev/null | wc -l)
        for dir in "$WORKSPACE_PATH"/*/; do
            if [ -d "$dir" ]; then
                local name=$(basename "$dir")
                local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
                echo "  • $name: $size"
            fi
        done
        echo "  Total de workspaces: $count"
    else
        echo "  Nenhum workspace ativo"
    fi

    # Processos ativos
    echo ""
    echo "Processos ativos no container:"
    docker exec "$CONTAINER_NAME" ps aux 2>/dev/null || true
}

watch_workspace() {
    local agent="${1:-}"
    local workspace

    if [ -n "$agent" ]; then
        workspace="$WORKSPACE_PATH/$agent"
    else
        # Pegar o workspace mais recente
        workspace=$(ls -dt "$WORKSPACE_PATH"/* 2>/dev/null | head -n1)
    fi

    if [ -z "$workspace" ] || [ ! -d "$workspace" ]; then
        log_error "Nenhum workspace encontrado"
        exit 1
    fi

    log_info "Monitorando workspace de: $(basename "$workspace")"
    echo ""
    echo "Pressione 'q' para sair"
    echo ""

    docker logs --follow --tail 200 2>/dev/null | \
        grep -E "(\[PROCESS\]|ERROR|Exception)" | \
        grep -v "^$" || true
}

# Menu interativo (apenas em terminal interactivo)
interactive_menu() {
    if [ -t 1 ]; then
        echo ""
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║           OpenClaw - Monitor Interativo                    ║"
        echo "╠══════════════════════════════════════════════════════════╣"
        echo "║  Comandos:                                                 ║"
        echo "║    tail[N]         Mostrar últimas N linhas (default: 50)  ║"
        echo "║    watch           Monitoramento em tempo real              ║"
        echo "║    recent[N]       Mostrar últimas N linhas (default: 100) ║"
        echo "║    stats           Estatísticas do container                ║"
        echo "║    watch[N]        Monitorar workspace específico            ║"
        echo "║    status          Status geral                             ║"
        echo "║    q, quit         Sair                                      ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
    fi
}

# Parsear argumentos
WATCH=0
TAIL_LINES=50
STATS=0
INTERACTIVE=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --watch|-w)
            WATCH=1
            shift
            ;;
        --tail|-t)
            TAIL_LINES=${2:-50}
            shift 2
            ;;
        --recent|-r)
            RECENT=${2:-100}
            shift 2
            ;;
        --stats|-s)
            STATS=1
            shift
            ;;
        --watch-ws)
            WATCH_WORKSPACE=1
            shift
            ;;
        --agent|-a)
            if [ -n "$2" ]; then
                WATCH_AGENT="$2"
                shift
            fi
            shift
            ;;
        -t)
            if [ -n "$2" ]; then
                TAIL_LINES="$2"
            fi
            shift
            ;;
        --help|-h)
            echo "OpenClaw Monitor de Saída"
            echo ""
            echo "Uso: $0 [opções]"
            echo ""
            echo "Opções:"
            echo "  --watch, -w            Monitoramento em tempo real"
            echo "  --tail, -t N           Mostrar últimas N linhas (default: 50)"
            echo "  --recent, -r N         Mostrar últimas N linhas (default: 100)"
            echo "  --stats, -s            Estatísticas do container"
            echo "  --watch-ws, -a [agent] Monitorar workspace específico"
            echo "  --help, -h             Mostrar ajuda"
            echo ""
            echo "Exemplos:"
            echo "  $0                    - Menu interativo"
            echo "  $0 --watch            - Monitoramento em tempo real"
            echo "  $0 --tail 50          - Últimas 50 linhas"
            echo "  $0 --stats            - Estatísticas"
            ;;
        *)
            echo "Opção não reconhecida: $1"
            echo "Use --help para ver as opções"
            exit 1
            ;;
    esac
done

# Executar comando
case "${WATCH:-0}${TAIL_LINES:-0}${STATS:-0}${INTERACTIVE:-0}" in
    1)
        watch_logs
        ;;
    01*)
        if [ -n "$WATCH_AGENT" ]; then
            watch_workspace "$WATCH_AGENT"
        else
            watch_logs
        fi
        ;;
    001)
        if [ -n "$RECENT" ]; then
            recent_logs "$RECENT"
        else
            recent_logs 100
        fi
        ;;
    001*)
        stats
        ;;
    *)
        interactive_menu
        echo ""
        tail_logs "$TAIL_LINES"
        echo ""
        read -p "Digite outro comando ou 'q' para sair: " cmd

        while [ "$cmd" != "q" ] && [ "$cmd" != "quit" ]; do
            case $cmd in
                tail*)
                    if [[ $cmd =~ ^tail([0-9]+)$ ]]; then
                        recent_logs "${BASH_REMATCH[1]}"
                    else
                        recent_logs "$TAIL_LINES"
                    fi
                    ;;
                recent*)
                    if [[ $cmd =~ ^recent([0-9]+)$ ]]; then
                        recent_logs "${BASH_REMATCH[1]}"
                    else
                        recent_logs 100
                    fi
                    ;;
                stats)
                    stats
                    ;;
                watch)
                    watch_logs
                    ;;
                *)
                    log_warn "Comando desconhecido: $cmd"
                    interactive_menu
                    ;;
            esac
            read -p "Digite outro comando ou 'q' para sair: " cmd
        done
        ;;
esac

exit 0
