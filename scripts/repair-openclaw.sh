#!/bin/bash

# No ambiente Docker deste projeto, os dados ficam na pasta 'data'
# Vamos verificar se o arquivo de config está lá
DOCKER_DATA_DIR="./data"

# Se a pasta .openclaw estiver dentro de data (comum no Docker)
if [ -d "$DOCKER_DATA_DIR/.openclaw" ]; then
    OPENCLAW_HOME="$DOCKER_DATA_DIR/.openclaw"
elif [ -d "$DOCKER_DATA_DIR" ]; then
    OPENCLAW_HOME="$DOCKER_DATA_DIR"
else
    echo "❌ Erro: Não foi possível encontrar a pasta de dados do OpenClaw."
    exit 1
fi

CONFIG_FILE="$OPENCLAW_HOME/openclaw.json"
SESSIONS_DIR="$OPENCLAW_HOME/agents/main/sessions"

echo "🚀 Iniciando Manutenção Docker (Alvo: $OPENCLAW_HOME)"

# 1. Limpeza do JSON (Plugin obsoleto)
if [ -f "$CONFIG_FILE" ]; then
    # Criar backup
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    # Remover linhas do plugin google-antigravity-auth
    sed -i '/google-antigravity-auth/d' "$CONFIG_FILE"
    echo "✅ Plugin google-antigravity-auth removido de $CONFIG_FILE"
    
    # 2. Ajustar permissões (silenciar o Doctor)
    chmod 600 "$CONFIG_FILE"
    chmod 700 "$OPENCLAW_HOME"
    echo "🔒 Permissões ajustadas."
else
    echo "⚠️  Aviso: openclaw.json não encontrado em $OPENCLAW_HOME"
    echo "Dica: Verifique se o ficheiro está na pasta 'config' em vez de 'data'."
fi

# 3. Limpeza de sessões órfãs
if [ -d "$SESSIONS_DIR" ]; then
    count=$(ls -1 "$SESSIONS_DIR"/*.jsonl 2>/dev/null | wc -l)
    if [ "$count" != "0" ]; then
        mkdir -p "$OPENCLAW_HOME/maintenance_backup"
        mv "$SESSIONS_DIR"/*.jsonl "$OPENCLAW_HOME/maintenance_backup/"
        echo "📂 $count arquivos de sessão órfãos movidos para backup."
    fi
fi

echo "---"
echo "✨ Reparação concluída!"
