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

# Antes de mudar para o usuário openclaw
RUN npm install -g @openclaw/brave-search    

# Instala Node.js (se necessário para plugins)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Cria um usuário não-root para segurança
RUN useradd -m -u 1000 -s /bin/bash openclaw \
    && mkdir -p /app /data /logs \
    && chown -R openclaw:openclaw /app /data /logs

# Diretório de trabalho
WORKDIR /app

# Copia arquivos de instalação se necessário
# COPY install.sh /app/install.sh

# Instala OpenClaw mas impede a execução do setup interativo durante o build
RUN curl -fsSL https://openclaw.ai/install.sh -o install_openclaw.sh \
    && chmod +x install_openclaw.sh \
    && ./install_openclaw.sh --only-bin || true \
    && rm install_openclaw.sh

# Configura variáveis de ambiente para o usuário openclaw
ENV PATH="/home/openclaw/.local/bin:${PATH}"
ENV OPENCLAW_HOME=/home/openclaw/.config/openclaw
ENV PYTHONUNBUFFERED=1

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

# Comando de inicialização com script de entrada
# No Dockerfile, verifique se está assim:
COPY --chown=openclaw:openclaw entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Comando de inicialização
ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]
CMD []
