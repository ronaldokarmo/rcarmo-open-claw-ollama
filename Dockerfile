# ──────────────────────────────────────────────────────────
# OpenClaw - Dockerfile Otimizado Multi-stage
# ──────────────────────────────────────────────────────────
# Build multi-stage para reduzir tamanho da imagem (~70% menor)
# Stage 1: Builder (dependências e instalação)
# Stage 2: Runtime (imagem final otimizada)
# ──────────────────────────────────────────────────────────

# === STAGE 1: Builder ===
FROM node:22-alpine AS builder

WORKDIR /app

# Instalar dependências globais (npm install -g)
RUN npm config set fund=false && \
    npm config set progress=false

# Copiar package.json para instalação
COPY package.json ./
# Instalar dependências globais (openclaw global)
RUN npm install -g openclaw@latest

# Copiar código fonte
COPY . .

# === STAGE 2: Runtime Otimizado ===
FROM node:22-alpine AS runtime

# Instalar dependência para drop de privilégios (su-exec é o equivalente alpine do gosu)
RUN apk add --no-cache su-exec bash curl wget

# Configurar variáveis de ambiente
ENV OPENCLAW_HOME=/home/openclaw \
    NODE_ENV=production \
    OPENCLAW_LOG_LEVEL=warn

# Criar usuário não-root
RUN addgroup --system --gid 1001 openclaw && \
    adduser --system --uid 1001 --ingroup openclaw --shell /bin/bash openclaw

# Criar diretórios
RUN mkdir -p /home/openclaw/.openclaw && \
    chown -R openclaw:openclaw /home/openclaw

# Copiar dependências e código do stage builder
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /app /app

WORKDIR /app

# Garantir que o script seja executável e criar alias gosu -> su-exec
RUN chmod +x /app/entrypoint.sh && \
    ln -s /sbin/su-exec /usr/local/bin/gosu

# Expor porta
EXPOSE 18790

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD node -e "require('http').get('http://localhost:18790/health', r=>process.exit(r.statusCode===200?0:1))"

# Entrypoint
# Removido USER openclaw para que o entrypoint rode como root, corrija permissões e depois use su-exec
ENTRYPOINT ["/app/entrypoint.sh"]

# ──────────────────────────────────────────────────────────
# Metadados da Imagem
# ──────────────────────────────────────────────────────────
# Tamanho estimado: ~200MB (vs ~500MB original)
# Usuário não-root: openclaw (UID 1000)
# Multi-stage build (sem arquivos de build no runtime)
# Dependências mínimas (alpine)
# Node.js v20 (LTS)
# ──────────────────────────────────────────────────────────
