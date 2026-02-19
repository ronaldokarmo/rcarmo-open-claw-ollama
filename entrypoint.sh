#!/bin/bash

export PATH="/home/openclaw/.local/bin:$PATH"
mkdir -p "$OPENCLAW_HOME/workspace" "$OPENCLAW_HOME/agents/main"

echo "🚀 OpenClaw Gateway iniciando..."
echo "Porta: 18789"
echo "API Keys configuradas:"
[ -n "$OPENROUTER_API_KEY" ] && echo "  ✅ OpenRouter"
[ -n "$GOOGLE_AI_KEY" ] && echo "  ✅ Gemini"  
[ -n "$GROQ_API_KEY" ] && echo "  ✅ Groq"
[ -n "$OLLAMA_API_BASE" ] && echo "  ✅ Ollama (Base: $OLLAMA_API_BASE)"
echo ""

# Verificar conectividade com Ollama se configurado
if [ -n "$OLLAMA_API_BASE" ]; then
  echo "🔍 Verificando conexão com Ollama..."
  if curl -s --connect-timeout 5 "$OLLAMA_API_BASE/api/tags" > /dev/null; then
    echo "  ✅ Conexão com Ollama estabelecida!"
  else
    echo "  ⚠️ Não foi possível conectar ao Ollama em $OLLAMA_API_BASE."
    echo "  Verifique se o container 'ollama' está rodando e acessível."
  fi
fi

# (Opcional) Habilitar Google Antigravity
# Descomente se quiser autoconfigura na primeira inicialização
openclaw plugins enable google-antigravity-auth || true

# Tentar iniciar o gateway - se falhar, aguardar e tentar novamente
while true; do
  # Token fornecido via env var OPENCLAW_GATEWAY_TOKEN (.env)
  openclaw gateway --port 18789 --allow-unconfigured &
  GATEWAY_PID=$!
  wait $GATEWAY_PID 2>/dev/null || true
  echo "[$(date)] Gateway saiu, reiniciando em 10s..."
  sleep 10
done

