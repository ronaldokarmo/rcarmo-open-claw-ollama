#!/bin/bash
set -e

echo "🔧 Configuração Automática do OpenClaw com Docker"

# Verifica se Docker está instalado e rodando
if ! docker info > /dev/null 2>&1; then
    echo "❌ Erro ao conectar com o Docker Daemon."
    echo "   Certifique-se de que o Docker Desktop está rodando."
    echo "   Se estiver no WSL, verifique se a integração com sua distro está ativada nas configurações do Docker Desktop -> Resources -> WSL Integration."
    exit 1
fi

# Verifica Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "📦 Instalando Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Clona repositório ou usa diretório atual
if [ ! -f "Dockerfile" ]; then
    echo "📁 Criando estrutura de diretórios..."
    mkdir -p openclaw-docker/{config,data,logs,nginx}
    cd openclaw-docker
fi

# Configuração do .env
if [ ! -f ".env" ]; then
    echo "📄 Criando arquivo .env a partir de .env.example..."
    cp .env.example .env
fi

# Carrega variáveis existentes para não pedir de novo se já estiverem lá
source .env 2>/dev/null || true

# Solicita chave do Gemini se não estiver configurada
if [ -z "$GEMINI_API_KEY" ] || [ "$GEMINI_API_KEY" = "sua-chave-aqui" ]; then
    read -p "🔑 Digite sua chave de API do Gemini: " INPUT_GEMINI_KEY
    if [ -n "$INPUT_GEMINI_KEY" ]; then
        # Atualiza a chave no .env (cross-platform sed)
        if grep -q "GEMINI_API_KEY=" .env; then
             sed -i "s|^GEMINI_API_KEY=.*|GEMINI_API_KEY=$INPUT_GEMINI_KEY|" .env
        else
             echo "GEMINI_API_KEY=$INPUT_GEMINI_KEY" >> .env
        fi
    fi
else
    echo "✅ Chave Gemini já configurada."
fi

# Constrói a imagem
echo "🐳 Construindo imagem Docker..."
docker-compose build

# Inicia os serviços
echo "🚀 Iniciando OpenClaw..."
docker-compose up -d

echo "⏳ Aguardando inicialização..."
sleep 10

# Testa a conexão
if curl -s http://localhost:18790/health > /dev/null; then
    echo "✅ OpenClaw está rodando!"
    echo "🌐 Dashboard: http://localhost:18790"
    echo "🔧 Para ver logs: docker-compose logs -f"
else
    echo "⚠️  Verificando status..."
    docker-compose logs openclaw | tail -20
fi
