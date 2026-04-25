#!/bin/bash
# Script de monitoramento da API OpenClaw
# Monitora endpoints, métricas e saúde

API_URL="${API_URL:-http://localhost:18790}"
LOG_FILE="/var/log/openclaw-api-monitor.log"
INTERVAL="${INTERVAL:-30}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_health() {
    log "Verificando health check..."
    response=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/health" 2>/dev/null)
    if [ "$response" == "200" ]; then
        log "✅ Health check OK"
        return 0
    else
        log "❌ Health check FAILED (HTTP $response)"
        return 1
    fi
}

check_metrics() {
    log "Verificando métricas..."
    metrics=$(curl -s "$API_URL/metrics" 2>/dev/null)
    if [ -n "$metrics" ]; then
        log "✅ Métricas coletadas"
        echo "$metrics" >> "$LOG_FILE"
        return 0
    else
        log "⚠️  Nenhuma métrica disponível"
        return 1
    fi
}

check_performance() {
    log "Verificando performance..."
    response=$(curl -s -w "Time: %{time_total}s" -o /dev/null "$API_URL/agents" 2>/dev/null)
    if echo "$response" | grep -q "Time:"; then
        time=$(echo "$response" | grep "Time:" | awk -F'Time: ' '{print $2}')
        if (( $(echo "$time < 1" | bc -l) )); then
            log "✅ Performance OK ($time segundos)"
            return 0
        else
            log "⚠️  Performance lenta ($time segundos)"
            return 1
        fi
    else
        log "⚠️  Endpoint /agents não respondendo"
        return 1
    fi
}

monitor() {
    log "Iniciando monitoramento da API..."
    log "API_URL=$API_URL"
    log "Intervalo=${INTERVAL}s"

    while true; do
        check_health
        check_metrics
        check_performance
        sleep "$INTERVAL"
    done
}

case "${1:-monitor}" in
    health)
        check_health
        ;;
    metrics)
        check_metrics
        ;;
    performance)
        check_performance
        ;;
    monitor)
        monitor
        ;;
    *)
        echo "Uso: $0 {health|metrics|performance|monitor}"
        exit 1
        ;;
esac
