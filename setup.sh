#!/bin/bash
set -e

echo "🔧 Configuração Automática do OpenClaw com Docker"

# Verifica se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não encontrado. Instalando..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo "✅ Docker instalado. Reinicie o terminal."
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

# Solicita chave do Gemini
read -p "🔑 Digite sua chave de API do Gemini: " GEMINI_API_KEY
echo "GEMINI_API_KEY=$GEMINI_API_KEY" > .env

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