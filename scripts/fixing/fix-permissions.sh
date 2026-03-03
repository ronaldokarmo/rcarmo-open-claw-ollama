#!/bin/bash
# fix-permissions.sh
# Corrige permissões do OpenClaw

set -e

echo "🔧 Corrigindo permissões do OpenClaw..."

# Parar container
echo "⏸️  Parando container..."
docker-compose stop openclaw

# Corrigir permissões
echo "🔐 Ajustando permissões..."
sudo chown -R 1000:1000 data/.openclaw/
sudo chmod -R 750 data/.openclaw/

# Verificar
echo ""
echo "📋 Verificando permissões:"
ls -la data/.openclaw/openclaw.json

# Reiniciar
echo ""
echo "🚀 Reiniciando OpenClaw..."
docker-compose up -d openclaw

echo ""
echo "✅ Pronto! Monitorando logs..."
echo "   (Pressione Ctrl+C para sair)"
echo ""
sleep 3
docker-compose logs -f openclaw
