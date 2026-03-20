#!/bin/bash

echo "🐳 Reparando OpenClaw através do Docker..."

# 1. Definir o modo do gateway diretamente via comando oficial do OpenClaw
# Isso corrige o erro de sintaxe e o bloqueio do gateway ao mesmo tempo
docker-compose run --rm gateway openclaw config set gateway.mode local

# 2. Corrigir a política do Telegram para evitar mensagens perdidas
docker-compose run --rm gateway openclaw config set channels.telegram.groupPolicy open

echo "---"
echo "♻️ Reiniciando os serviços..."
docker-compose restart

echo "✅ Concluído! Verifique os logs agora."
