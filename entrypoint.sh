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
# Verificar WSL2 systemd
# ========================================
check_wsl2_systemd() {
    # Detecta se está rodando no WSL2
    if grep -qi microsoft /proc/version 2>/dev/null; then
        log "🐧 WSL2 detectado"
        
        # Verifica se systemd está habilitado
        if ! systemctl --version >/dev/null 2>&1; then
            error "❌ systemd NÃO está habilitado no WSL2!"
            echo ""
            echo "╔════════════════════════════════════════════════════════════════╗"
            echo "║                  ⚠️  AÇÃO NECESSÁRIA (HOST)                   ║"
            echo "╚════════════════════════════════════════════════════════════════╝"
            echo ""
            echo "  WSL2 precisa do systemd habilitado para OpenClaw funcionar."
            echo ""
            echo "  📝 PASSOS PARA CORRIGIR NO WINDOWS/POWERSHELL:"
            echo ""
            echo "  1. No WSL2, edite o arquivo /etc/wsl.conf (fora do container):"
            echo "     sudo nano /etc/wsl.conf"
            echo ""
            echo "  2. Adicione estas linhas:"
            echo "     [boot]"
            echo "     systemd=true"
            echo ""
            echo "  3. No PowerShell (como Administrador), execute:"
            echo "     wsl --shutdown"
            echo ""
            echo "  4. Reabra seu terminal WSL2 e reinicie o projeto."
            echo ""
            echo "  🔍 Verificação: systemctl --user status"
            echo ""
            echo "╚════════════════════════════════════════════════════════════════╝"
            echo ""
            
            # Aguarda 5 segundos para usuário ler
            sleep 5
            
            # Tenta continuar mesmo assim
            warn "⚠️ Tentando continuar sem systemd (pode haver falhas)..."
        else
            log "✅ systemd habilitado (versão: $(systemctl --version | head -1))"
        fi
    fi
}

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

# Verificar WSL2 systemd primeiro
check_wsl2_systemd

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

# Fix permissions for the openclaw user (ownership first)
log "Corrigindo ownership dos volumes..."
chown -R openclaw:openclaw "${OPENCLAW_HOME}/.openclaw" "${OPENCLAW_HOME}/logs"

# Verificar e corrigir permissões de segurança
check_and_fix_permissions

# Handle configuration: setup if missing, repair if existing
if [ ! -f "${OPENCLAW_HOME}/.openclaw/openclaw.json" ]; then
    log "Primeira execução - configurando..."
    gosu openclaw openclaw setup --non-interactive || gosu openclaw openclaw doctor --fix || true
    
    # Após criar config, ajustar permissões novamente
    check_and_fix_permissions
else
    log "Testando permissão de escrita..."
    gosu openclaw touch "${OPENCLAW_HOME}/.openclaw/write_test" && log "✅ Escrita OK" || warn "❌ Falha na escrita!"
    rm -f "${OPENCLAW_HOME}/.openclaw/write_test" 2>/dev/null || true
    
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
