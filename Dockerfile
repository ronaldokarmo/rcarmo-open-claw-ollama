# ─────────────────────────────────────────────
# Stage 1: deps — instala Node.js e dependências do sistema
# ─────────────────────────────────────────────
FROM ubuntu:22.04 AS deps

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Instala Node.js v22 via nodesource
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────
# Stage 2: runtime — imagem final enxuta
# ─────────────────────────────────────────────
FROM ubuntu:22.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Dependências mínimas de runtime INCLUINDO Node.js setup
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    git \
    python3 \
    python3-pip \
    gosu \
    docker.io \
    vim \
    lsof \
    psmisc \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Usuário não-root dedicado
RUN useradd -m -u 1000 -s /bin/bash openclaw \
    && mkdir -p \
    /app \
    /home/openclaw/.local/bin \
    /home/openclaw/.openclaw \
    /home/openclaw/.cache \
    && chown -R openclaw:openclaw \
    /home/openclaw

# Instala OpenClaw globalmente
ARG OPENCLAW_VERSION=latest
RUN npm install -g openclaw@${OPENCLAW_VERSION} --unsafe-perm \
    && npm cache clean --force

# Symlink docker CLI
RUN ln -sf /usr/bin/docker /usr/local/bin/docker

# Variáveis de ambiente - CORRIGIDO OPENCLAW_HOME
ENV PATH="/usr/local/bin:/usr/bin:/home/openclaw/.local/bin:${PATH}"
ENV OPENCLAW_HOME=/home/openclaw
ENV NODE_OPTIONS="--dns-result-order=ipv4first"

WORKDIR /app

# Copia e sanitiza o entrypoint
COPY --chown=openclaw:openclaw entrypoint.sh /app/entrypoint.sh
RUN sed -i 's/\r$//' /app/entrypoint.sh \
    && chmod +x /app/entrypoint.sh \
    && bash -n /app/entrypoint.sh

# Expõe porta do gateway
EXPOSE 18790

# Volumes persistentes
VOLUME ["/home/openclaw/.openclaw"]

# Healthcheck
HEALTHCHECK \
    --interval=30s \
    --timeout=10s \
    --start-period=60s \
    --retries=5 \
    CMD curl -sf -o /dev/null -w "%{http_code}" http://localhost:18790/ \
    | grep -qE "^(200|405)$" || exit 1

USER root

ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]
