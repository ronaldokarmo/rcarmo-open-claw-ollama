#!/bin/bash
set -e

log() { echo -e "\033[0;32m[entrypoint]\033[0m $(date +%H:%M:%S) $1"; }
warn() { echo -e "\033[1;33m[entrypoint]\033[0m $(date +%H:%M:%S) $1"; }
error() { echo -e "\033[0;31m[entrypoint]\033[0m $(date +%H:%M:%S) $1"; }

# ========================================
# Garantir OPENCLAW_HOME
# ========================================
if [ -z "$OPENCLAW_HOME" ] || [ "$OPENCLAW_HOME" = "/" ]; then
    warn "⚠️ OPENCLAW_HOME não definida ou inválida (/). Usando \$HOME ($HOME)"
    OPENCLAW_HOME="$HOME"
fi

# ========================================
# Verificar e Corrigir Permissões de Segurança
# ========================================
check_and_fix_permissions() {
    local openclaw_dir="${OPENCLAW_HOME}/.openclaw"
    local config_file="${openclaw_dir}/openclaw.json"
    
    log "🔐 Corrigindo permissões de segurança..."
    
    # Garantir ownership primeiro
    chown -R openclaw:openclaw "$openclaw_dir" 2>/dev/null || true
    
    # Tentar forçar permissões restritas
    if [ -d "$openclaw_dir" ]; then
        chmod 700 "$openclaw_dir" 2>/dev/null || true
        local dir_perms=$(stat -c '%a' "$openclaw_dir" 2>/dev/null || echo "unknown")
        
        if [ "$dir_perms" != "700" ] && [[ "$dir_perms" != "unknown" ]]; then
            warn "⚠️ Não foi possível definir permissões 700 em $openclaw_dir (atual: $dir_perms)"
            warn "   Isso ocorre em volumes montados do Windows (E:\) sem suporte a metatada."
            warn "   DICA: Use o sistema de arquivos nativo do WSL (ex: ~/openclaw-docker) para evitar isso."
        fi
    fi
    
    if [ -f "$config_file" ]; then
        chmod 600 "$config_file" 2>/dev/null || true
        local file_perms=$(stat -c '%a' "$config_file" 2>/dev/null || echo "unknown")
        
        if [ "$file_perms" != "600" ] && [[ "$file_perms" != "unknown" ]]; then
            warn "⚠️ Não foi possível definir permissões 600 em $config_file (atual: $file_perms)"
        fi
    fi
    
    log "✅ Verificação de permissões concluída."
}

# ========================================
# Main checks
# ========================================


# Check Docker socket
[ -S /var/run/docker.sock ] && log "✅ Docker socket detectado" || warn "⚠️ Docker socket não encontrado"

# Create directories
log "Criando estrutura de diretórios..."
mkdir -p "${OPENCLAW_HOME}/.openclaw" "${OPENCLAW_HOME}/logs"

# Clean locks
log "Limpando travas antigas..."
find "${OPENCLAW_HOME}/.openclaw" -name "*.lock" -delete 2>/dev/null || true

# Banner
cat << "EOF"

╔══════════════════════════════════════════╗
║       🚀 OpenClaw Gateway iniciando      ║
╚══════════════════════════════════════════╝
EOF

echo "  Porta   : ${OPENCLAW_PORT:-18790}"
echo "  Modelo  : ${OPENCLAW_MODEL:-ollama}"
echo "  Ollama  : ${OLLAMA_API_BASE:-http://ollama:11434}"
echo ""

# Wait for Ollama
if [ -n "${OLLAMA_API_BASE}" ]; then
    log "Verificando Ollama..."
    for i in $(seq 1 30); do
        curl -sf "${OLLAMA_API_BASE}/api/tags" >/dev/null 2>&1 && { log "✅ Ollama conectado!"; break; }
        [ $i -eq 30 ] && warn "⚠️  Ollama timeout"
        sleep 2
    done
fi

# Fix permissions for the openclaw user (ownership first) - skip if it takes too long on Windows mounts
log "Corrigindo ownership dos volumes..."
timeout 10 chown -R openclaw:openclaw "${OPENCLAW_HOME}/.openclaw" "${OPENCLAW_HOME}/logs" 2>/dev/null || warn "⚠️ Chown timeout ou falha (esperado em volumes Windows)"

# Verificar e corrigir permissões de segurança
check_and_fix_permissions || true

# Handle configuration: setup if missing, repair if existing
if [ ! -f "${OPENCLAW_HOME}/.openclaw/openclaw.json" ]; then
    log "Primeira execução - configurando..."
    openclaw setup --non-interactive 2>/dev/null || openclaw doctor --fix 2>/dev/null || true
    check_and_fix_permissions 2>/dev/null || true
else
    log "Testando permissão de escrita..."
    if touch "${OPENCLAW_HOME}/.openclaw/write_test" 2>/dev/null; then
        log "✅ Escrita OK"
    else
        warn "⚠️ Escrita indisponível (volume Windows?), continuando..."
    fi
    rm -f "${OPENCLAW_HOME}/.openclaw/write_test" 2>/dev/null || true
    
    log "Verificando esquema da configuração..."
    openclaw doctor --non-interactive 2>/dev/null || warn "⚠️ Falha ao verificar configuração"
fi

# Start the gateway directly
log "Iniciando OpenClaw Gateway..."
log "WebSocket endpoint: ws://0.0.0.0:${OPENCLAW_PORT:-18790}"

# Start TCP proxy to expose openclaw on all interfaces (0.0.0.0:18790 -> 127.0.0.1:18791)
# OpenClaw always binds to 127.0.0.1, so we need this relay for Nginx/Docker bridge access
node -e "
const net = require('net');
const server = net.createServer(client => {
  const upstream = net.connect(18791, '127.0.0.1');
  client.pipe(upstream);
  upstream.pipe(client);
  client.on('error', () => {});
  upstream.on('error', () => {});
});
server.listen(18790, '0.0.0.0', () => {
  process.stdout.write('[proxy] TCP relay 0.0.0.0:18790 -> 127.0.0.1:18791\n');
});
" 2>/dev/null &

# Try su-exec first; if it fails, run as root
log "Iniciando gateway..."
if su-exec openclaw openclaw gateway --port 18791 --allow-unconfigured 2>/dev/null; then
    exec su-exec openclaw openclaw gateway --port 18791 --allow-unconfigured
else
    log "⚠️ su-exec falhou, executando como root..."
    exec openclaw gateway --port 18791 --allow-unconfigured
fi
