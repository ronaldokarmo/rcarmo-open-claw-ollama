# Estrutura de Dados OpenClaw

## Dados do OpenClaw

### Arquivos
- Dockerfile otimizado
- docker-compose.yml
- .env
- Scripts de operação
- Configurações de cache

### Bancos de Dados
- PostgreSQL principal
- Redis cache
- SQLite temporário

### Arquivos de Dados
- Logs estruturados
- Métricas em tempo real
- Cache de respostas
- Arquivos temporários

### Cache de Agentes
- Respostas de agentes
- Metadados de context
- Sessões de usuário

## Organização

### /data
- Dados persistentes
- Backups
- Logs rotacionados

### /tmp
- Arquivos temporários
- Sessions
- Process locks

### /var/log/openclaw
- Logs estruturados
- Métricas
- Audit trails
