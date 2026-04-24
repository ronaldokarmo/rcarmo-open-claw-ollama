#!/bin/bash
# Script para implementar cache entre chamadas de agentes

# 1. Criar diretório para cache
mkdir -p /opt/openclaw/cache/agents

# 2. Configurar arquivo de cache com TTL (7 dias)
cat > /opt/openclaw/cache/config << 'EOF'
CACHE_ENABLED=true
CACHE_TTL=604800  # 7 dias em segundos
CACHE_MAX_SIZE=100
CACHE_PATH=/opt/openclaw/cache/agents
EOF

echo "✅ Cache de agentes configurado!"
