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
RUN npm config set unsafe-perm true && \
    npm config set fund=false && \
    npm config set progress=false && \
    npm config set fund=false

# Copiar package.json para instalação
COPY package.json ./
# Instalar dependências globais (openclaw global)
RUN npm install -g openclaw

# Copiar código fonte
COPY . .

# === STAGE 2: Runtime Otimizado ===
FROM node:22-alpine AS runtime

# Configurar variáveis de ambiente
ENV OPENCLAW_HOME=/home/openclaw \
    NODE_ENV=production \
    OPENCLAW_LOG_LEVEL=warn

# Criar usuário não-root
RUN addgroup --system --gid 1000 openclaw && \
    adduser --system --uid 1000 --ingroup openclaw --shell /bin/bash openclaw

# Criar diretórios
RUN mkdir -p /home/openclaw/.openclaw && \
    chown -R openclaw:openclaw /home/openclaw

# Copiar dependências e código do stage builder
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder --chown=openclaw:openclaw /app /app

# Configurar usuário
USER openclaw
WORKDIR /app

# Expor porta
EXPOSE 18790

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD node -e "require('http').get('http://localhost:18790/health', r=>process.exit(r.statusCode===200?0:1))"

# Entrypoint
ENTRYPOINT ["npx", "openclaw"]

# ──────────────────────────────────────────────────────────
# Metadados da Imagem
# ──────────────────────────────────────────────────────────
# Tamanho estimado: ~200MB (vs ~500MB original)
# Usuário não-root: openclaw (UID 1000)
# Multi-stage build (sem arquivos de build no runtime)
# Dependências mínimas (alpine)
# Node.js v22 (LTS)
# ──────────────────────────────────────────────────────────
