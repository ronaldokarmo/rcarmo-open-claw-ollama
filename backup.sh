#!/bin/bash

# Script de backup para o OpenClaw Docker
# Cria backup dos arquivos importantes do projeto

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/openclaw-$TIMESTAMP.tar.gz"

# Criar diretório de backup se não existir
mkdir -p "$BACKUP_DIR"

echo "=== Backup do OpenClaw Docker ==="
echo "Data: $(date)"
echo "Diretório de backup: $BACKUP_DIR"

# Copiar arquivos para backup
echo ""
echo "Copiando arquivos para backup..."

# Arquivos do Docker
[ -f "$PROJECT_ROOT/docker-compose.yml" ] && cp "$PROJECT_ROOT/docker-compose.yml" "$BACKUP_DIR/"
[ -f "$PROJECT_ROOT/docker-compose.override.yml" ] && cp "$PROJECT_ROOT/docker-compose.override.yml" "$BACKUP_DIR/"
[ -f "$PROJECT_ROOT/Dockerfile" ] && cp "$PROJECT_ROOT/Dockerfile" "$BACKUP_DIR/"

# Scripts e configuração
[ -f "$PROJECT_ROOT/entrypoint.js" ] && cp "$PROJECT_ROOT/entrypoint.js" "$BACKUP_DIR/"
[ -f "$PROJECT_ROOT/settings.json" ] && cp "$PROJECT_ROOT/settings.json" "$BACKUP_DIR/"
[ -f "$PROJECT_ROOT/backup.sh" ] && cp "$PROJECT_ROOT/backup.sh" "$BACKUP_DIR/"
[ -f "$PROJECT_ROOT/monitor.sh" ] && cp "$PROJECT_ROOT/monitor.sh" "$BACKUP_DIR/"
[ -f "$PROJECT_ROOT/startup.sh" ] && cp "$PROJECT_ROOT/startup.sh" "$BACKUP_DIR/"

# Documentação (arquivos .md)
[ -d "$PROJECT_ROOT/docs" ] && find "$PROJECT_ROOT/docs" -name "*.md" -exec cp {} "$BACKUP_DIR/" \; 2>/dev/null

# Arquivos de configuração do projeto
[ -f "$PROJECT_ROOT/.gitignore" ] && cp "$PROJECT_ROOT/.gitignore" "$BACKUP_DIR/"
[ -f "$PROJECT_ROOT/README.md" ] && cp "$PROJECT_ROOT/README.md" "$BACKUP_DIR/"

echo ""
echo "Criando arquivo de backup..."

# Criar backup excluindo arquivos que não devem ser copiados
tar -czf "$BACKUP_FILE" \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='backup' \
    --exclude='.claude' \
    --exclude='*.db' \
    --exclude='*.log' \
    --exclude='*.pid' \
    --exclude='__pycache__' \
    --exclude='ollama_data' \
    --exclude='*.sqlite' \
    --exclude='*.sqlite3' \
    -C "$PROJECT_ROOT" .

if [ $? -eq 0 ]; then
    echo ""
    echo "=== Backup concluído com sucesso! ==="
    echo "Arquivo de backup: $BACKUP_FILE"
    echo "Tamanho: $(du -h "$BACKUP_FILE" 2>/dev/null | cut -f1 || echo 'N/A')"
    echo ""
    echo "Para restaurar:"
    echo "  1. Remover backup/ ou mover o backup"
    echo "  2. Excluir o arquivo de backup antigo"
    echo "  3. rodar npm install"
    echo "  4. Rodar docker-compose up -d"
else
    echo ""
    echo "=== Erro ao criar backup ==="
    exit 1
fi
