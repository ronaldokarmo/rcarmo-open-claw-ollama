# Use uma imagem base mais leve para produção
FROM ubuntu:22.04 AS builder

# Evita prompts interativos durante a instalação
ENV DEBIAN_FRONTEND=noninteractive

# Define variáveis de ambiente para versões
ENV OPENCLAW_VERSION=latest
ENV PYTHONUNBUFFERED=1

# Atualiza e instala dependências básicas
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Instala Node.js v22 (Requisito OpenClaw)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Cria um usuário não-root para segurança
RUN useradd -m -u 1000 -s /bin/bash openclaw \
    && mkdir -p /app /data /logs /home/openclaw/.local/bin \
    && chown -R openclaw:openclaw /app /data /logs /home/openclaw

# Instala OpenClaw GLOBALMENTE para evitar problemas de PATH
# E permite que o script use o binário de qualquer lugar
RUN npm install -g openclaw@latest --unsafe-perm

# Diretório de trabalho
WORKDIR /app

# Configura variáveis de ambiente
ENV PATH="/usr/bin:/usr/local/bin:/home/openclaw/.local/bin:${PATH}"
ENV OPENCLAW_HOME=/home/openclaw/.config/openclaw
ENV PYTHONUNBUFFERED=1

# Copia script de entrada e garante que tenha quebras de linha Unix (LF)
COPY --chown=openclaw:openclaw entrypoint.sh /app/entrypoint.sh
RUN sed -i 's/\r$//' /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Muda para usuário não-root
USER openclaw

# Cria diretórios de configuração
RUN mkdir -p ${OPENCLAW_HOME} /home/openclaw/.cache

# Expor portas necessárias
EXPOSE 18789

# Configura volumes para persistência
VOLUME ["/home/openclaw/.config/openclaw", "/data", "/logs"]

# Health check para verificar se o serviço está saudável
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:18789/health || exit 1

# Comando de inicialização
ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]
CMD []
