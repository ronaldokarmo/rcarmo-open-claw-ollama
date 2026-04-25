# Saúde e Observabilidade OpenClaw

## Health Checks

### API Health
- `/v1/agent/health` - Verifica status do agente
- `/health/live` - Liveness probe
- `/health/ready` - Readiness probe

### Observabilidade
- Prometheus metrics endpoint
- Grafana dashboards
- Structured logging (JSON)

### Circuit Breakers
- Failsafe patterns
- Timeout handling
- Retry logic

## Métricas Principais

### Response Times
- Agent chat latência
- Cache hit ratios
- Queue depths

### Erros
- Timeout counts
- Memory spikes
- Disk I/O waits

### Recursos
- CPU usage
- Memory per agent
- Network connections

## Stack de Monitoramento

### Prometheus
- Scrape configs
- Metric definitions
- Alerting rules

### Grafana
- Dashboards
- Data sources
- Visualizations

### Logging
- Filebeat/Fluentd
- Elasticsearch
- Kibana
