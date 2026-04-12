# ─────────────────────────────────────────────
# Single-stage build: runtime otimizado
# ─────────────────────────────────────────────
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1

# Instalar dependências essenciais de uma vez (reduz layers + tamanho)
# Removido: vim, lsof, psmisc (não-essenciais em production)
# Node.js v22 via NodeSource (compatível com debian:bookworm-slim)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    git \
    python3 \
    python3-pip \
    gosu \
    docker.io \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm cache clean --force \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Criar usuário não-root e diretórios
RUN useradd -m -u 1000 -s /bin/bash openclaw \
    && mkdir -p /app /home/openclaw/.local/bin /home/openclaw/.openclaw /home/openclaw/.cache \
    && chown -R openclaw:openclaw /home/openclaw \
    && ln -sf /usr/bin/docker /usr/local/bin/docker

# Variáveis de ambiente
ENV PATH="/usr/local/bin:/usr/bin:/home/openclaw/.local/bin:${PATH}" \
    OPENCLAW_HOME=/home/openclaw \
    NODE_OPTIONS="--dns-result-order=ipv4first"

# Instalar OpenClaw globalmente
ARG OPENCLAW_VERSION=latest
RUN npm install -g openclaw@${OPENCLAW_VERSION} --unsafe-perm

WORKDIR /app

# Copiar e validar entrypoint
COPY --chown=openclaw:openclaw entrypoint.sh /app/entrypoint.sh
RUN sed -i 's/\r$//' /app/entrypoint.sh \
    && chmod +x /app/entrypoint.sh \
    && bash -n /app/entrypoint.sh

# Expor porta do gateway
EXPOSE 18790

# Volumes persistentes
VOLUME ["/home/openclaw/.openclaw"]

# Healthcheck
HEALTHCHECK \
    --interval=30s \
    --timeout=10s \
    --start-period=60s \
    --retries=5 \
    CMD curl -sf -o /dev/null -w "%{http_code}" http://localhost:18790/ | grep -qE "^(200|405)$" || exit 1

ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]
