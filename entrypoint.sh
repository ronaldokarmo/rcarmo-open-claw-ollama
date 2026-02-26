#!/bin/bash

# Fix Docker socket permissions if it exists
if [ -S /var/run/docker.sock ]; then
    chmod 666 /var/run/docker.sock
fi

export PATH="/home/openclaw/.local/bin:$PATH"
mkdir -p "$OPENCLAW_HOME/workspace" "$OPENCLAW_HOME/agents/main"
# Ajusta ownership apenas nos diretórios que não são read-only
chown openclaw:openclaw "$OPENCLAW_HOME" 2>/dev/null || true
chown -R openclaw:openclaw "$OPENCLAW_HOME/workspace" "$OPENCLAW_HOME/agents" 2>/dev/null || true

echo "🚀 OpenClaw Gateway iniciando..."
echo "Porta: 18789"
echo "API Keys configuradas:"

[ -n "$OLLAMA_API_BASE" ] && echo "  ✅ Ollama (Base: $OLLAMA_API_BASE)"
echo ""

echo "🧹 Limpando travas de sessão antigas..."
find "$OPENCLAW_HOME" -name "*.lock" -delete 2>/dev/null || true
echo ""

# Verificar conectividade com Ollama se configurado
if [ -n "$OLLAMA_API_BASE" ]; then
  echo "🔍 Verificando conexão com Ollama em $OLLAMA_API_BASE..."
  MAX_RETRIES=12
  RETRY_COUNT=0
  while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s --connect-timeout 5 "$OLLAMA_API_BASE/api/tags" > /dev/null; then
      echo "  ✅ Conexão com Ollama estabelecida!"
      break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "  ⏳ Aguardando Ollama ($RETRY_COUNT/$MAX_RETRIES)..."
    sleep 10
  done
  if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
    echo "  🔍 Verificando modelos disponíveis..."
    if ! curl -s "$OLLAMA_API_BASE/api/tags" | grep -q "llama3.1-fast:latest"; then
      echo "  📥 Baixando modelo llama3.1-fast:latest (necessário para subagents)..."
      curl -s -X POST "$OLLAMA_API_BASE/api/pull" -d '{"name": "llama3.1-fast:latest"}' > /dev/null
      echo "  ✅ Download do modelo iniciado em segundo plano!"
    else
      echo "  ✅ Modelo configurado."
    fi
    echo "  ⏳ Aguardando estabilização do Ollama..."
    sleep 5
  else
    echo "  ⚠️ Não foi possível conectar ao Ollama após várias tentativas. Pulando verificação de modelos."
  fi
fi

# Iniciar o gateway usando gosu para trocar para o usuário openclaw
while true; do
  gosu openclaw openclaw gateway --port 18789 --bind lan --allow-unconfigured &
  GATEWAY_PID=$!
  wait $GATEWAY_PID 2>/dev/null || true
  echo "[$(date)] Gateway saiu, reiniciando em 10s..."
  sleep 10
done

