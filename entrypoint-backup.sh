#!/bin/bash
set -e

log() { echo -e "\033[0;32m[entrypoint]\033[0m $(date +%H:%M:%S) $1"; }
warn() { echo -e "\033[1;33m[entrypoint]\033[0m $(date +%H:%M:%S) $1"; }

# Check Docker socket
[ -S /var/run/docker.sock ] && log "✅ Docker socket detectado" || warn "⚠️  Docker socket não encontrado"

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
echo "  Modelo  : ${OPENCLAW_MODEL:-ollama/qwen2.5:1.5b}"
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

# Fix permissions for the openclaw user
log "Corrigindo permissões de volumes..."
chown -R openclaw:openclaw "${OPENCLAW_HOME}/.openclaw" "${OPENCLAW_HOME}/logs"
chmod -R 755 "${OPENCLAW_HOME}/.openclaw"
chmod -R 700 "${OPENCLAW_HOME}/.openclaw/openclaw.json"
log "Permissões corrigidas:" && ls -la "${OPENCLAW_HOME}/.openclaw"

# Fix WSL2


# Handle configuration: setup if missing, repair if existing
if [ ! -f "${OPENCLAW_HOME}/.openclaw/openclaw.json" ]; then
    log "Primeira execução - configurando..."
    gosu openclaw openclaw setup --non-interactive || gosu openclaw openclaw doctor --fix || true
else
    log "Testando permissão de escrita..."
    gosu openclaw touch "${OPENCLAW_HOME}/.openclaw/write_test" && log "✅ Escrita OK" || warn "❌ Falha na escrita!"
    log "Verificando/Reparando esquema da configuração..."
    gosu openclaw openclaw doctor --fix || warn "⚠️ Falha ao reparar configuração automaticamente"
fi

# Start the gateway directly
log "Iniciando OpenClaw Gateway..."
log "WebSocket endpoint: ws://0.0.0.0:${OPENCLAW_PORT:-18790}"

# Start TCP proxy to expose openclaw on all interfaces (0.0.0.0:18790 -> 127.0.0.1:18791)
# OpenClaw always binds to 127.0.0.1, so we need this relay for Nginx/Docker bridge access
gosu openclaw node -e "
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
" &

# Run gateway on internal port 18791 as PID 1 (exec ensures signals are forwarded correctly)
# Using gosu to drop root privileges and run as openclaw user
exec gosu openclaw openclaw gateway --port 18791 --force
