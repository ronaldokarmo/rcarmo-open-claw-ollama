# Use uma imagem base mais leve para produção
FROM ubuntu:22.04 AS builder

# Evita prompts interativos durante a instalação
ENV DEBIAN_FRONTEND=noninteractive

# Define variáveis de ambiente para versões
ENV OPENCLAW_VERSION=latest
ENV PYTHONUNBUFFERED=1

# 1. ATUALIZAÇÃO: Incluímos docker.io nas dependências para resolver o ENOENT
RUN apt-get update && apt-get install -y \
    curl \
    vim \
    ca-certificates \
    git \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    docker.io \
    gosu \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Instala Node.js v22 (Requisito OpenClaw)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Cria um usuário não-root para segurança
RUN useradd -m -u 1000 -s /bin/bash openclaw && \
    usermod -aG root openclaw && \
    mkdir -p /app /data /logs /home/openclaw/.local/bin && \
    chown -R openclaw:openclaw /app /data /logs /home/openclaw

# Instala OpenClaw GLOBALMENTE
RUN npm install -g openclaw@latest --unsafe-perm

# Symlink do docker para /usr/local/bin (acessível em subshells restritos)
RUN ln -sf /usr/bin/docker /usr/local/bin/docker

# Diretório de trabalho
WORKDIR /app

# Configura variáveis de ambiente
ENV PATH="/usr/bin:/usr/local/bin:/home/openclaw/.local/bin:${PATH}"
ENV OPENCLAW_HOME=/home/openclaw/.config/openclaw

# Copia script de entrada
COPY --chown=openclaw:openclaw entrypoint.sh /app/entrypoint.sh
RUN sed -i 's/\r$//' /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Muda para usuário root para permitir ajustes no socket no entrypoint
USER root

# Cria diretórios de configuração
RUN mkdir -p ${OPENCLAW_HOME} /home/openclaw/.cache

# Expor portas
EXPOSE 18789

# Configura volumes
VOLUME ["/home/openclaw/.config/openclaw", "/data", "/logs"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:18789/health || exit 1

ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]
