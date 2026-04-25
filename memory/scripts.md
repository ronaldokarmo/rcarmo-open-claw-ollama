# Scripts de Operação OpenClaw

## Scripts Principais

### deploy.sh
- Deploy otimizado
- Health checks automáticos
- Rollback automático
- Monitoramento pós-deploy

### backup.sh
- Backup incremental
- Compressão com tar + gzip
- Upload remoto (S3/Web)
- Rotação de backups
- Verificação de integridade
- Retenção configurável
- Verificação de integridade (MD5)

### cleanup.sh
- Limpeza de temporários
- Logs antigos
- Swaps
- Session files
- Arquivos >100MB
- Relatórios detalhados

### monitor-api.sh
- Health checks contínuos
- Métricas de latência
- Alertas de erro
- Utilização de recursos

## Utilização

### Deploy
```bash
./scripts/deploy.sh
# Monitora o deploy
# Verifica health checks
# Rollback se falhar
```

### Backup
```bash
./scripts/backup.sh full       # Backup completo
./scripts/backup.sh incremental # Backup incremental
./scripts/backup.sh remote     # Upload remoto
```

### Limpeza
```bash
./scripts/cleanup.sh full       # Limpeza completa
./scripts/cleanup.sh temp       # Apenas temporários
./scripts/cleanup.sh logs       # Apenas logs
./scripts/cleanup.sh report     # Relatório
```

## Cron Jobs

### Backup Diário
```bash
0 2 * * * /scripts/backup.sh daily
```

### Cleanup Semanal
```bash
0 3 * * 0 /scripts/cleanup.sh
```

### Monitoramento Contínuo
```bash
*/5 * * * * /scripts/monitor-api.sh
```
