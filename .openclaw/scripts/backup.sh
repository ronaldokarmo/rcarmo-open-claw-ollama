#!/bin/bash
# ────────────────────────────────────────────────────────────────
# OpenClaw - Script de Backup
# ────────────────────────────────────────────────────────────────
# Usage: ./backup.sh [full|config|logs] [output_dir]
# ────────────────────────────────────────────────────────────────

set -e

# Configurações
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGICAL_VOLUME_PATH="$PROJECT_ROOT/data"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.openclaw-backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
DATE_SUFFIX=$(date +%Y%m%d_%H%M%S)
CONTAINER_NAME="openclaw"

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
}

# Backup via Docker Volume
backup_volume() {
    local volume_name="$1"
    local backup_name="$2"
    local target_path="$3"

    log_section "Backup de $volume_name"

    # Montar volume em container temporário
    local temp_container="openclaw-temp-backup-$$"

    docker run --rm \
        --name "$temp_container" \
        --volumes-from "$CONTAINER_NAME" \
        -v "$target_path:/backup:Z" \
        alpine:latest \
        cp -r /"$volume_name" /backup/ 2>/dev/null || true

    # Listar o que foi backupado
    log_info "Backup de $volume_name salvo em: $target_path"
    ls -lh "$target_path/$volume_name" 2>/dev/null || true

    # Remover container temporário
    docker rm -f "$temp_container" 2>/dev/null || true

    # Compactar backup
    local backup_file="$target_path/$backup_name.tar.gz"
    if [ -d "$target_path/$volume_name" ]; then
        tar -czf "$backup_file" -C "$target_path" "$volume_name" 2>/dev/null || true
        log_info "Backup compactado: $backup_file"
    fi
}

# Backup de dados
backup_data() {
    log_section "Backup completo de dados"

    # Preparar diretório de backup
    local backup_dir="$BACKUP_ROOT/$DATE_SUFFIX"
    mkdir -p "$backup_dir"

    # Backup dos dados persistentes
    if [ -d "$LOGICAL_VOLUME_PATH" ]; then
        log_info "Backup de dados de aplicação..."
        tar -czf "$backup_dir/data.tar.gz" -C "$PROJECT_ROOT" "$LOGICAL_VOLUME_PATH"
        log_info "Salvo em: $backup_dir/data.tar.gz"
    fi

    # Backup de configuração
    if [ -f "$PROJECT_ROOT/.env" ]; then
        log_info "Backup de configurações..."
        mkdir -p "$backup_dir/config"
        cp "$PROJECT_ROOT/.env" "$backup_dir/config/.env.bak"
        log_info "Salvo em: $backup_dir/config/.env.bak"
    fi

    # Backup de logs (opcional, apenas os mais recentes)
    if [ -d "$PROJECT_ROOT/logs" ]; then
        log_info "Backup de logs recentes (últimas 100 linhas)..."
        mkdir -p "$backup_dir/logs"
        for logfile in "$PROJECT_ROOT/logs"/*.log; do
            if [ -f "$logfile" ]; then
                local basename=$(basename "$logfile" .log)
                head -n 100 "$logfile" > "$backup_dir/logs/${basename}.recent.log" 2>/dev/null || true
            fi
        done
        log_info "Salvo em: $backup_dir/logs/"
    fi

    # Backup do workspace do agent (se existir)
    if [ -d "$PROJECT_ROOT/.openclaw/workspace" ]; then
        log_info "Backup de workspaces dos agents..."
        cp -r "$PROJECT_ROOT/.openclaw/workspace" "$backup_dir/workspace/"
        log_info "Salvo em: $backup_dir/workspace/"
    fi

    log_info "Backup completo realizado"
    log_info "Localização: $backup_dir"

    # Listar arquivos de backup
    echo ""
    log_info "Arquivos de backup criados:"
    ls -lh "$backup_dir"/*.tar.gz 2>/dev/null || true
}

# Backup de logs
backup_logs() {
    log_section "Backup de logs"

    local backup_dir="$BACKUP_ROOT/logs/$DATE_SUFFIX"
    mkdir -p "$backup_dir"

    if [ -d "$PROJECT_ROOT/logs" ]; then
        log_info "Backup de logs..."
        if command -v tar &> /dev/null; then
            tar -czf "$backup_dir/openclaw-logs.tar.gz" -C "$PROJECT_ROOT" logs
        else
            cp -r "$PROJECT_ROOT/logs" "$backup_dir/"
        fi
        log_info "Salvo em: $backup_dir/openclaw-logs.tar.gz"
    else
        log_warn "Diretório de logs não encontrado"
    fi
}

# Backup de configuração
backup_config() {
    log_section "Backup de configuração"

    local backup_dir="$BACKUP_ROOT/config/$DATE_SUFFIX"
    mkdir -p "$backup_dir"

    # Backup de .env
    if [ -f "$PROJECT_ROOT/.env" ]; then
        cp "$PROJECT_ROOT/.env" "$backup_dir/.env.bak"
        log_info "Salvo: $backup_dir/.env.bak"
    fi

    # Backup de docker-compose
    if [ -f "$PROJECT_ROOT/docker-compose.yml" ]; then
        cp "$PROJECT_ROOT/docker-compose.yml" "$backup_dir/docker-compose.yml.bak"
        log_info "Salvo: $backup_dir/docker-compose.yml.bak"
    fi

    # Backup de .openclaw (se existir e não for backupado separadamente)
    if [ -d "$PROJECT_ROOT/.openclaw" ]; then
        log_info "Backup de ~/.openclaw..."
        if [ -d "$LOGICAL_VOLUME_PATH" ]; then
            # Já será backupado no backup completo
            log_info "Ignorando (já backupado no backup de dados)"
        else
            cp -r "$PROJECT_ROOT/.openclaw" "$backup_dir/"
            log_info "Salvo em: $backup_dir/"
        fi
    fi

    log_info "Backup de configuração realizado"
}

# Listar backups
list_backups() {
    log_section "Listando Backups"

    if [ -d "$BACKUP_ROOT" ]; then
        echo ""
        echo "Diretório de backups: $BACKUP_ROOT"
        echo ""

        if [ -d "$BACKUP_ROOT" ]; then
            echo "Backups disponíveis:"
            echo ""

            # Listar backups por data
            for dir in "$BACKUP_ROOT"/*/; do
                if [ -d "$dir" ]; then
                    local date_str=$(basename "$dir")
                    echo "📦 $date_str:"

                    for file in "$dir"/*.tar.gz "$dir"/*.bak; do
                        if [ -f "$file" ]; then
                            local size=$(du -h "$file" | cut -f1)
                            local age=$(( ($(date +%s) - $(stat -c %Y "$file")) / 86400 ))
                            local status="OK"

                            if [ "$age" -gt "$RETENTION_DAYS" ]; then
                                status="EXPIRED"
                            fi

                            printf "  • %-40s %s (%s dias)\n" "$(basename "$file")" "$size" "$age"
                        fi
                    done
                    echo ""
                fi
            done

            # Estatísticas
            echo "Estatísticas:"
            local total_backups=$(find "$BACKUP_ROOT" -name "*.tar.gz" -o -name "*.bak" 2>/dev/null | wc -l)
            local total_size=$(du -sh "$BACKUP_ROOT" 2>/dev/null | cut -f1)
            echo "  Total de backups: $total_backups"
            echo "  Total de espaço: $total_size"
        else
            echo "Diretório de backups não existe"
        fi
    else
        echo "Configuração de backup não encontrada"
        echo "Use BACKUP_ROOT=/caminho/para/backups para definir"
    fi
}

# Limpar backups antigos
cleanup_old_backups() {
    log_section "Limpando backups antigos"

    log_info "Removendo backups com mais de $RETENTION_DAYS dias..."

    local removed=0
    local freed=0

    for file in $(find "$BACKUP_ROOT" -name "*.tar.gz" -o -name "*.bak" 2>/dev/null); do
        if [ -f "$file" ]; then
            local age=$(( ($(date +%s) - $(stat -c %Y "$file")) / 86400 ))
            if [ "$age" -gt "$RETENTION_DAYS" ]; then
                log_info "Removendo: $(basename "$file") (idade: $age dias)"
                rm -f "$file"
                ((removed++))
            fi
        fi
    done

    # Atualizar tamanho do diretório
    freed=$(du -sh "$BACKUP_ROOT" 2>/dev/null | cut -f1)

    log_info "Limpeza concluída: $removed backups removidos"
    log_info "Espace liberado: $(du -sh "$BACKUP_ROOT" 2>/dev/null | cut -f1) -> $freed"
}

# Principais comandos
case "${1:-}" in
    full|all)
        check_docker
        backup_data
        ;;
    data)
        check_docker
        backup_data
        ;;
    logs)
        backup_logs
        ;;
    config)
        backup_config
        ;;
    list)
        list_backups
        ;;
    cleanup|clean)
        cleanup_old_backups
        ;;
    *)
        echo "OpenClaw Backup Script"
        echo ""
        echo "Uso: $0 [comando] [opções]"
        echo ""
        echo "Comandos:"
        echo "  full,all     - Backup completo (dados + config + logs recentes)"
        echo "  data         - Backup dos dados da aplicação"
        echo "  logs         - Backup de logs recentes"
        echo "  config       - Backup de configurações"
        echo "  list         - Listar backups disponíveis"
        echo "  cleanup      - Limpar backups antigos (> $RETENTION_DAYS dias)"
        echo ""
        echo "Variáveis de ambiente:"
        echo "  BACKUP_ROOT  - Diretório de backup padrão ($BACKUP_ROOT)"
        echo "  RETENTION_DAYS - Dias de retenção padrão ($RETENTION_DAYS)"
        echo ""
        echo "Exemplos:"
        echo "  $0 full              - Backup completo"
        echo "  $0 data              - Backup apenas de dados"
        echo "  $0 list              - Listar backups"
        echo "  $0 cleanup           - Limpar backups antigos"
        ;;
esac
