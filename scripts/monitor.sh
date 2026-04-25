#!/bin/bash
# ────────────────────────────────────────────────────────────────
# Monitoramento de Sistema OpenClaw
# ────────────────────────────────────────────────────────────────
# Funções:
#   1. Monitorar recursos (CPU, memória, disk)
#   2. Monitorar saúde dos containers
#   3. Alertas por e-mail/Telegram
#   4. Logs de performance
# ────────────────────────────────────────────────────────────────

# Configurações
MAX_CPU_PERCENT="${MAX_CPU_PERCENT:-80}"
MAX_MEMORY_PERCENT="${MAX_MEMORY_PERCENT:-85}"
MAX_DISK_PERCENT="${MAX_DISK_PERCENT:-80}"
CHECK_INTERVAL="${CHECK_INTERVAL:-30}"  # segundos
ALERT_EMAIL="${ALERT_EMAIL}"
ALERT_TELEGRAM="${ALERT_TELEGRAM}"
LOG_FILE="/var/log/openclaw/monitor.log"
METRICS_DIR="/var/log/openclaw/metrics"

# Criar diretórios
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$METRICS_DIR"

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

# Enviar alerta
send_alert() {
  local message="$1"
  local severity="${2:-INFO}"

  # Salvar no log
  log_info "[${severity}] $message"

  # E-mail (se configurado)
  if [ -n "$ALERT_EMAIL" ] && command -v mail &> /dev/null; then
    echo "$message" | mail -s "OpenClaw Alert: $severity" "$ALERT_EMAIL" 2>/dev/null || true
  fi

  # Telegram (se configurado)
  if [ -n "$ALERT_TELEGRAM" ] && command -v curl &> /dev/null; then
    curl -s -X POST "https://api.telegram.org/bot$ALERT_TELEGRAM/sendMessage" \
      -d "chat_id=-1001894668501" \
      -d "text=*OpenClaw Alert: $severity*\n$message" \
      -d "parse_mode=markdown" 2>/dev/null || true
  fi
}

# Monitorar recursos do sistema
check_resources() {
  log_info "Verificando recursos do sistema..."

  # CPU
  local cpu_usage
  cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null)
  if [ -z "$cpu_usage" ]; then
    cpu_usage=$(vmstat 1 2 | tail -1 | awk '{print int($15)}')
  fi

  if [ -n "$cpu_usage" ] && [ "$cpu_usage" -gt "$MAX_CPU_PERCENT" ]; then
    send_alert "CPU Usage: ${cpu_usage}% (limit: ${MAX_CPU_PERCENT}%)" "WARNING"
  fi
  log_info "CPU: ${cpu_usage}%"

  # Memória
  local mem_usage
  mem_usage=$(free | grep Mem | awk '{print int($3/$2 * 100)}')

  if [ -n "$mem_usage" ] && [ "$mem_usage" -gt "$MAX_MEMORY_PERCENT" ]; then
    send_alert "Memória: ${mem_usage}% (limit: ${MAX_MEMORY_PERCENT}%)" "WARNING"
  fi
  log_info "Memória: ${mem_usage}%"

  # Disco
  local disk_usage
  disk_usage=$(df / | tail -1 | awk '{print int($5)}')

  if [ -n "$disk_usage" ] && [ "$disk_usage" -gt "$MAX_DISK_PERCENT" ]; then
    send_alert "Disco: ${disk_usage}% (limit: ${MAX_DISK_PERCENT}%)" "WARNING"
  fi
  log_info "Disco: ${disk_usage}%"

  # Container saúde
  log_info "Verificando containers Docker..."

  # OpenClaw container
  if ! docker ps | grep -q "openclaw"; then
    send_alert "Container openclaw não está rodando!" "CRITICAL"
    log_error "Container openclaw ausente!"
    return 1
  fi

  # Ollama container
  if ! docker ps | grep -q "ollama"; then
    send_alert "Container ollama não está rodando!" "CRITICAL"
    log_error "Container ollama ausente!"
    return 1
  fi

  # Hermes container
  if ! docker ps | grep -q "hermes"; then
    send_alert "Container hermes não está rodando!" "WARNING"
    log_warn "Container hermes ausente"
  fi

  log_success "Todos os containers estão saudáveis"

  # Salvar métricas
  save_metrics
}

# Salvar métricas
save_metrics() {
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)

  cat > "$METRICS_DIR/metrics_${timestamp}.json" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "cpu_percent": $((cpu_usage)),
  "memory_percent": $((mem_usage)),
  "disk_percent": $((disk_usage)),
  "container_status": {
    "openclaw": "$(docker ps | grep openclaw | grep -c Up)",
    "ollama": "$(docker ps | grep ollama | grep -c Up)",
    "hermes": "$(docker ps | grep hermes | grep -c Up)"
  }
}
EOF
}

# Dashboard rápido
dashboard() {
  echo ""
  echo "╔═══════════════════════════════════════════════╗"
  echo "║   OpenClaw System Status Dashboard            ║"
  echo "╚═══════════════════════════════════════════════╝"
  echo ""

  echo "📊 Recursos do Sistema:"
  echo "  CPU:        $(top -bn1 | grep Cpu(s) | awk '{print $2}' | cut -d'%' -f1)%"
  echo "  Memória:    $(free | grep Mem | awk '{print $3/$2 * 100}')%"
  echo "  Disco /:    $(df / | tail -1 | awk '{print $5}')"
  echo ""

  echo "📦 Containers Docker:"
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | while read line; do
    echo "  $line"
  done
  echo ""

  echo "🕐 Tempo de atividade:"
  docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -5
  echo ""

  echo "╔═══════════════════════════════════════════════╗"
  echo "║   Gerado: $(date)                          ║"
  echo "╚═══════════════════════════════════════════════╝"
  echo ""
}

# Loop de monitoramento
monitor_loop() {
  log_info "Iniciando loop de monitoramento (intervalo: ${CHECK_INTERVAL}s)"
  log_info "Pressione Ctrl+C para parar"
  echo ""

  local last_check
  last_check=$(date +%s)

  while true; do
    current_check=$(date +%s)
    elapsed=$((current_check - last_check))

    if [ "$elapsed" -ge "$CHECK_INTERVAL" ]; then
      check_resources
      last_check=$current_check
    fi

    sleep 1
  done
}

# Script para rodar periodicamente (ex: via cron)
run_check() {
  check_resources
}

# Uso
usage() {
  echo "Uso: $0 <command>"
  echo ""
  echo "Comandos:"
  echo "  loop     - Loop contínuo de monitoramento"
  echo "  check    - Executar verificação única"
  echo "  dashboard - Mostrar dashboard rápido"
  echo "  help     - Mostrar este help"
  echo ""
  echo "Variáveis de ambiente:"
  echo "  MAX_CPU_PERCENT    - Limite de CPU (%)"
  echo "  MAX_MEMORY_PERCENT - Limite de memória (%)"
  echo "  MAX_DISK_PERCENT   - Limite de disco (%)"
  echo "  CHECK_INTERVAL     - Intervalo entre checks (segundos)"
  echo "  ALERT_EMAIL        - E-mail para alertas"
  echo "  ALERT_TELEGRAM     - Token de bot Telegram para alertas"
  echo ""
  exit 1
}

# Principal
case "${1:-help}" in
  loop)
    monitor_loop
    ;;
  check)
    run_check
    ;;
  dashboard)
    dashboard
    ;;
  *)
    usage
    ;;
esac
