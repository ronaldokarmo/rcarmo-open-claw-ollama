#!/usr/bin/env node

const net = require('net');
const { execSync, spawn } = require('child_process');
const path = require('path');

// Configurações
const OPENCLAW_PORT = process.env.OPENCLAW_PORT || 18790;
const OPENCLAW_HOME = process.env.OPENCLAW_HOME || process.env.HOME;
const OPENCLAW_PROXY_PORT = 18790;
const OPENCLAW_INTERNAL_PORT = 18791;

const log = (msg) => console.log(`[entrypoint] ${msg}`);
const warn = (msg) => console.warn(`[entrypoint] ${msg}`);

// Garantir OPENCLAW_HOME
if (!OPENCLAW_HOME || OPENCLAW_HOME === '/') {
  warn('⚠️ OPENCLAW_HOME não definida ou inválida (/). Usando $HOME');
  OPENCLAW_HOME = process.env.HOME;
}

// Wait for Ollama
if (process.env.OLLAMA_API_BASE) {
  log('Verificando Ollama...');
  const ollamaUrl = process.env.OLLAMA_API_BASE;
  let attempts = 0;

  const checkOllama = setInterval(() => {
    try {
      const response = await fetch(ollamaUrl + '/api/tags');
      if (response.ok) {
        log('✅ Ollama conectado!');
        clearInterval(checkOllama);
      } else if (attempts >= 30) {
        warn('⚠️  Ollama timeout');
        clearInterval(checkOllama);
      }
    } catch (err) {
      attempts++;
      if (attempts >= 30) clearInterval(checkOllama);
    }
  }, 2000);
}

// Criar diretórios
log('Criando estrutura de diretórios...');
try {
  execSync(`mkdir -p "${OPENCLAW_HOME}/.openclaw" "${OPENCLAW_HOME}/logs"`);
} catch (err) {
  // Diretórios já existem
}

// Banner
console.log('\n╔══════════════════════════════════════════╗');
console.log('║       🚀 OpenClaw Gateway iniciando      ║');
console.log('╚══════════════════════════════════════════╝');

console.log('  Porta   :', OPENCLAW_PORT);
console.log('  Modelo  :', process.env.OPENCLAW_MODEL || 'ollama/qwen2.5:1.5b');
console.log('  Ollama  :', process.env.OLLAMA_API_BASE || 'http://ollama:11434');
console.log('');

// Start TCP proxy
log('Iniciando TCP proxy...');
const proxyServer = net.createServer((client) => {
  const upstream = net.connect(OPENCLAW_INTERNAL_PORT, '127.0.0.1');

  client.pipe(upstream);
  upstream.pipe(client);

  client.on('error', () => {});
  upstream.on('error', () => {});

  upstream.on('connect', () => {
    process.stdout.write(`[proxy] TCP relay 0.0.0.0:${OPENCLAW_PORT} -> 127.0.0.1:${OPENCLAW_INTERNAL_PORT}\n`);
  });
});

proxyServer.listen(OPENCLAW_PROXY_PORT, '0.0.0.0', () => {
  console.log('[proxy] Proxy listening on 0.0.0.0:' + OPENCLAW_PROXY_PORT);
});

console.log('✅ Proxy TCP iniciado!');

// Start gateway
console.log('\n[proxy] Iniciando OpenClaw Gateway...');
console.log('[proxy] WebSocket endpoint: ws://0.0.0.0:' + OPENCLAW_PORT);

// Spawn o gateway
const gatewayProcess = spawn('openclaw', ['gateway', '--port', String(OPENCLAW_INTERNAL_PORT)], {
  stdio: 'inherit'
});

gatewayProcess.on('error', (err) => {
  console.error('[proxy] Erro ao iniciar gateway:', err.message);
  process.exit(1);
});

gatewayProcess.on('exit', (code) => {
  console.log('[proxy] Gateway encerrado com código:', code);
  process.exit(code || 0);
});

// Handle Ctrl+C
process.on('SIGINT', () => {
  console.log('\n[proxy] Encerrando gracefully...');
  gatewayProcess.kill('SIGTERM');
  process.stdout.write('\n[proxy] OpenClaw Gateway encerrado.\n');
  process.exit(0);
});
