# Métricas e Monitoramento OpenClaw

## Métricas Principais

### Response Times
- `/v1/agent/chat/submit` - Tempo de resposta da API principal
- `/v1/agent/health` - Latência do sistema
- `/v1/agent/metrics` - Métricas agregadas por endpoint

### Disponibilidade
- Uptime dos containers
- Health checks
- Failsafe activation count
- Circuit breaker states

### Performance
- Cache hit/miss ratios
- Queue depth
- Agent spawn times
- Streaming latencies

### Erros
- 4xx/5xx counts
- Timeout rates
- Memory usage spikes
- Disk I/O wait times

### Recursos
- CPU usage per container
- Memory per agent
- Disk usage
- Network connections
