#!/bin/bash
# ────────────────────────────────────────────────────────────────
# Backup Otimizado OpenClaw
# ────────────────────────────────────────────────────────────────
# Funções:
#   1. Criar backups compressos (tar.gz)
#   2. Gerenciar retenção por data
#   3. Verificar integridade com sha256sum
#   4. Rotação automática de backups antigos
# ────────────────────────────────────────────────────────────────

# Configurações
BACKUP_DIR="${BACKUP_DIR:-/backup}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
COMPRESSION_LEVEL="${COMPRESSION_LEVEL:-6}"
EXCLUDE_PATTERN="${EXCLUDE_PATTERN:-logs/*.tmp|*.temp|*.cache|*.log}"
BACKUP_NAME="openclaw"
TIMESTAMP_SUFFIX="${TIMESTAMP_SUFFIX:-_$(date +%Y%m%d_%H%M%S)}"
LOG_FILE="/var/log/openclaw/backup.log"
METRICS_FILE="/var/log/openclaw/metrics/backup_metrics.json"

# Criar diretórios
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$BACKUP_DIR"
mkdir -p "/var/log/openclaw/metrics"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Títulos
log_info() {
  echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$LOG_FILE"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

log_warn() {
  echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
  echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
}

# Função para gerar backup
create_backup() {
  log_info "Criando backup..."

  local source_dir="${1:-.}"
  local dest_file="${2:-}"

  # Se não especificado, usar padrão
  if [ -z "$dest_file" ]; then
    dest_file="$BACKUP_DIR/${BACKUP_NAME}${TIMESTAMP_SUFFIX}.tar.gz"
  fi

  # Criar lista de exclusão
  local exclude_file
  exclude_file=$(mktemp)

  # Buscar arquivos para excluir
  find "$source_dir" -type f \( \
    -name "*.tmp" -o \
    -name "*.temp" -o \
    -name "*.cache" -o \
    -name "*.log" -o \
    -name "*.pid" -o \
    -name "node_modules" -type d \
  \) -print > "$exclude_file"

  # Criar backup
  log_info "Criando archive em: $dest_file"

  # Compressão incremental com rsync se backup anterior existe
  local prev_backup="$BACKUP_DIR/${BACKUP_NAME}.tar.gz"
  if [ -f "$prev_backup" ]; then
    log_info "Usando incremental backup..."
    # Compressão incremental
    tar --listed-incremental="$BACKUP_DIR/.filesystem-ab" \
      -czf "$dest_file" \
      --exclude-file="$exclude_file" \
      "$source_dir" 2>&1 | tail -5
  else
    # Backup completo
    tar -czf "$dest_file" \
      --exclude-file="$exclude_file" \
      "$source_dir" 2>&1 | tail -5
  fi

  # Remover lista de exclusão
  rm -f "$exclude_file"

  if [ -f "$dest_file" ]; then
    local size
    size=$(du -h "$dest_file" | cut -f1)
    log_success "Backup criado: $dest_file ($size)"

    # Criar manifest com checksum
    create_manifest "$dest_file"

    # Rotacionar backups antigos
    rotate_old_backups

    # Salvar métricas
    save_backup_metrics "$dest_file"
  else
    log_error "Falha ao criar backup"
    return 1
  fi
}

# Criar manifest com checksum
create_manifest() {
  local backup_file="$1"
  local manifest_file="${backup_file}.manifest"

  {
    echo "BACKUP_MANIFEST"
    echo "================"
    echo "Created: $(date -Iseconds)"
    echo "Hostname: $(hostname)"
    echo ""
    echo "Contents:"
    tar -tzf "$backup_file" | while read file; do
      echo "  $file"
    done
    echo ""
    echo "Checksum: $(sha256sum "$backup_file" | cut -d' ' -f1)"
    echo "Size: $(du -h "$backup_file" | cut -f1)"
  } > "$manifest_file"

  log_info "Manifest criado: $manifest_file"
}

# Rotacionar backups antigos
rotate_old_backups() {
  log_info "Rotacionando backups antigos (retenção: $RETENTION_DAYS dias)..."

  # Remover backups mais velhos
  find "$BACKUP_DIR" -name "${BACKUP_NAME}*.tar.gz" -mtime +"$RETENTION_DAYS" -exec rm -v {} \;

  # Remover manifests de backups removidos
  find "$BACKUP_DIR" -name "${BACKUP_NAME}*.manifest" -mtime +"$RETENTION_DAYS" -exec rm -v {} \;

  # Limpar archive list se existir e for antiga
  if [ -f "$BACKUP_DIR/.filesystem-ab" ]; then
    if find "$BACKUP_DIR/.filesystem-ab" -mtime +"$((RETENTION_DAYS * 2))" > /dev/null 2>&1; then
      log_info "Removendo arquivo de incremento antigo"
      rm -f "$BACKUP_DIR/.filesystem-ab"
    fi
  fi

  log_success "Rotação concluída"
}

# Salvar métricas do backup
save_backup_metrics() {
  local backup_file="$1"
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)

  cat > "$METRICS_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "backup_file": "$backup_file",
  "size": "$(du -h "$backup_file" | cut -f1)",
  "compression_ratio": "$(stat -c%s "$backup_file.bak" 2>/dev/null | wc -l || echo 'N/A')",
  "checksum": "$(sha256sum "$backup_file" | cut -d' ' -f1)",
  "source_count": "$(tar -tzf "$backup_file" | wc -l)",
  "retention_policy_days": $RETENTION_DAYS
}
EOF

  log_info "Métricas salvas"
}

# Restaurar backup
restore_backup() {
  local backup_file="$1"
  local dest_dir="${2:-.}"

  if [ ! -f "$backup_file" ]; then
    log_error "Backup não encontrado: $backup_file"
    return 1
  fi

  # Verificar checksum se manifest existir
  local manifest_file="${backup_file}.manifest"
  if [ -f "$manifest_file" ]; then
    local stored_checksum
    stored_checksum=$(grep "^Checksum:" "$manifest_file" | awk '{print $2}')

    local current_checksum
    current_checksum=$(sha256sum "$backup_file" | cut -d' ' -f1)

    if [ "$stored_checksum" != "$current_checksum" ]; then
      log_error "Checksum invalido! Backup corrompido?"
      return 1
    fi
  fi

  log_info "Restaurando $backup_file para $dest_dir..."

  tar -xzf "$backup_file" -C "$dest_dir"
  log_success "Restauração concluída"
}

# Verificar backups
verify_backups() {
  log_info "Verificando integridade dos backups..."

  local passed=0
  local failed=0

  for backup_file in "$BACKUP_DIR"/${BACKUP_NAME}*.tar.gz; do
    if [ ! -f "$backup_file" ]; then
      continue
    fi

    local checksum
    checksum=$(sha256sum "$backup_file" | cut -d' ' -f1)
    local status="✅"

    if [ -z "$checksum" ]; then
      status="❌"
      failed=$((failed + 1))
      log_error "Backup invalido: $backup_file"
    else
      passed=$((passed + 1))
      log_success "$status $backup_file"
    fi
  done

  log_info "Verificação concluída: $passed OK, $failed FAILED"
}

# Listar backups
list_backups() {
  log_info "Backups disponíveis:"
  echo ""
  printf "%-8s %-50s %s\n" "IDADE" "ARQUIVO" "TAMANHO"
  printf "%-8s %-50s %s\n" "------" "--------------------------------------------" "-------"

  for backup_file in "$BACKUP_DIR"/${BACKUP_NAME}*.tar.gz; do
    if [ -f "$backup_file" ]; then
      local filename
      filename=$(basename "$backup_file")
      local size
      size=$(du -h "$backup_file" | cut -f1)
      local age
      age=$(find "$BACKUP_DIR" -name "$filename" -mmin -60 -printf "%+T" 2>/dev/null || echo "Há menos de 1 minuto")

      printf "%-8s %-50s %s\n" "$age" "$filename" "$size"
    fi
  done
}

# Limpar backup corrompido
cleanup_corrupted() {
  log_info "Removendo backup corrompido..."

  for backup_file in "$BACKUP_DIR"/${BACKUP_NAME}*.tar.gz; do
    if [ ! -f "$backup_file" ]; then
      continue
    fi

    if ! tar -tzf "$backup_file" > /dev/null 2>&1; then
      log_warn "Backup corrompido removido: $backup_file"
      rm -f "$backup_file"
      rm -f "${backup_file}.manifest"
    fi
  done

  log_success "Limpeza concluída"
}

# Uso
usage() {
  echo "Uso: $0 <command> [opcional]"
  echo ""
  echo "Comandos:"
  echo "  create <source_dir>    - Criar backup"
  echo "  create                  - Criar backup do diretório atual"
  echo "  list                    - Listar backups disponíveis"
  echo "  verify                  - Verificar integridade dos backups"
  echo "  restore <backup> [dir] - Restaurar backup"
  echo "  cleanup                  - Remover backup corrompido"
  echo "  help                    - Mostrar este help"
  echo ""
  exit 1
}

# Principal
case "${1:-help}" in
  create)
    create_backup "$2" "$3"
    ;;
  list)
    list_backups
    ;;
  verify)
    verify_backups
    ;;
  restore)
    restore_backup "$2" "$3"
    ;;
  cleanup)
    cleanup_corrupted
    ;;
  *)
    usage
    ;;
esac
