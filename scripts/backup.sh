#!/bin/bash
BACKUP_DIR="/backup/openclaw"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p $BACKUP_DIR

# Backup de volumes
docker run --rm \
  -v openclaw_db_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/all-data-$TIMESTAMP.tar.gz /data

# Backup de imagens
docker save -o $BACKUP_DIR/images-$TIMESTAMP.tar openclaw:latest

# Backup de configurações
cp docker-compose.yml $BACKUP_DIR/
tar czf $BACKUP_DIR/config-$TIMESTAMP.tar.gz openclaw/.openclaw/config/

echo "Backup concluído em $BACKUP_DIR"
