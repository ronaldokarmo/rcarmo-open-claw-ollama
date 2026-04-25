#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────────
# Cleanup OpenClaw - Limpeza de Arquivos Temporários
# ─────────────────────────────────────────────────────────────────────────────────

# Configurações
EXCLUDE_PATTERNS="node_modules|.git|backup|logs|cache"
TIMESTAMP_FORMAT="%Y%m%d_%H%M%S"
LOG_FILE="/var/log/openclaw/cleanup.log"

# Criar diretórios
mkdir -p "$(dirname "$LOG_FILE")"

log_info() {
  echo -e "[${TIMESTAMP_FORMAT}] ℹ️  $1" | tee -a "$LOG_FILE"
}

log_warn() {
  echo -e "[${TIMESTAMP_FORMAT}] ⚠️  $1" | tee -a "$LOG_FILE"
}

# Função principal
cleanup() {
  log_info "Iniciando limpeza de arquivos temporários..."

  local temp_count=0
  local log_count=0
  local pid_count=0
  local total_size=0

  # Limpar arquivos temporários
  find /tmp -type f -name "*.tmp" -delete 2>/dev/null && log_info "Arquivos .tmp removidos"
  find /tmp -type f -name "*.temp" -delete 2>/dev/null && log_info "Arquivos .temp removidos"
  find /tmp -type f -name "*.cache" -delete 2>/dev/null && log_info "Cache limpo"

  # Limpar logs antigos (> 7 dias)
  find . -type f -name "*.log" -mtime +7 -delete 2>/dev/null && log_info "Logs antigos removidos (>7 dias)"
  find . -type f -name "*.log" -mtime +30 -exec rm -v {} \; && log_warn "Logs muito antigos removidos (>30 dias)"

  # Limpar arquivos PID
  find /tmp -type f -name "*.pid" -delete 2>/dev/null && pid_count=$((pid_count + 1))

  # Limpar session locks
  find . -type f -name "*.lock" -mtime +1 -delete 2>/dev/null && log_info "Session locks antigos removidos"

  # Limpar arquivos de swap temporários
  find /tmp -type f -name "swap*" -delete 2>/dev/null && log_info "Swaps temporários removidos"

  # Limpar arquivos com mais de 100MB (exceto backups)
  find . -type f -size +100M ! -path "*/backup/*" -exec rm -v {} \; 2>/dev/null

  # Limpar session files do docker
  rm -f /tmp/docker*.pid 2>/dev/null && log_info "Docker session files limpos"

  local current_size
  current_size=$(du -sh /tmp 2>/dev/null | cut -f1)

  log_info "Limpeza concluída! /tmp usa agora: $current_size"

  # Gerar relatório
  generate_report
}

# Gerar relatório
generate_report() {
  local report_file="/tmp/cleanup_report_$(date +%Y%m%d_%H%M%S).txt"

  {
    echo "=== RELATÓRIO DE LIMPEZA OPENCLAW ==="
    echo "Data: $(date)"
    echo ""
    echo "Arquivos limpos:"
    echo "  - Arquivos .tmp, .temp, .cache"
    echo "  - Logs antigos (>7 dias)"
    echo "  - Arquivos PID"
    echo "  - Session locks"
    echo "  - Swaps temporários"
    echo ""
    echo "Estatísticas de /tmp:"
    echo "  $(du -sh /tmp 2>/dev/null | awk '{print "    Total: " $1}')"
    echo ""
    echo "Status: ✅ Limpeza concluída"
  } > "$report_file"

  log_info "Relatório salvo em: $report_file"
}

# Uso
usage() {
  echo "Uso: $0 [opcional]"
  echo ""
  echo "Comandos:"
  echo "  full       - Limpeza completa (padrão)"
  echo "  temp       - Limpar apenas temporários"
  echo "  logs       - Limpar apenas logs antigos"
  echo "  report     - Gerar relatório sem limpar"
  echo "  help       - Mostrar este help"
  echo ""
  exit 1
}

# Principal
case "${1:-full}" in
  full)
    cleanup
    ;;
  temp)
    find /tmp -type f \( -name "*.tmp" -o -name "*.temp" -o -name "*.cache" -o -name "*.pid" \) -delete 2>/dev/null
    log_info "Temporários limpos"
    ;;
  logs)
    find . -type f -name "*.log" -mtime +7 -delete 2>/dev/null
    log_info "Logs antigos limpos"
    ;;
  report)
    generate_report
    ;;
  *)
    usage
    ;;
esac
