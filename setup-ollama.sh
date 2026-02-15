#!/bin/bash

# 🦞 OpenClaw + Ollama - Script de Inicialização e Testes
# Uso: chmod +x setup-ollama.sh && ./setup-ollama.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}🦞 OpenClaw + Ollama - Setup Script${NC}"
echo -e "${BLUE}================================================${NC}\n"

# ============ FUNÇÕES ============

check_docker() {
    echo -e "${YELLOW}Verificando Docker...${NC}"
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker não encontrado!${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker encontrado${NC}"
}

check_docker_compose() {
    echo -e "${YELLOW}Verificando Docker Compose...${NC}"
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose não encontrado!${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker Compose encontrado${NC}"
}

start_containers() {
    echo -e "\n${YELLOW}🐳 Iniciando containers...${NC}"
    
    if [ ! -f "docker-compose.yml" ]; then
        if [ -f "docker-compose-integrated.yml" ]; then
            cp docker-compose-integrated.yml docker-compose.yml
            echo -e "${GREEN}✅ Copiado docker-compose-integrated.yml → docker-compose.yml${NC}"
        else
            echo -e "${RED}❌ Arquivo docker-compose não encontrado!${NC}"
            exit 1
        fi
    fi
    
    docker-compose down --remove-orphans 2>/dev/null || true
    sleep 2
    docker-compose up -d --build
    echo -e "${GREEN}✅ Containers iniciados${NC}"
}

wait_for_services() {
    echo -e "\n${YELLOW}⏳ Aguardando serviços ficarem prontos...${NC}"
    
    # Aguardar Ollama
    echo "  Aguardando Ollama..."
    for i in {1..30}; do
        if docker exec ollama curl -s http://localhost:11434/api/tags &>/dev/null; then
            echo -e "  ${GREEN}✅ Ollama pronto${NC}"
            break
        fi
        sleep 2
        echo -n "."
    done
    
    # Aguardar Nginx
    echo -e "\n  Aguardando Nginx..."
    for i in {1..20}; do
        if docker exec openclaw-proxy curl -s http://localhost:80 &>/dev/null; then
            echo -e "  ${GREEN}✅ Nginx pronto${NC}"
            break
        fi
        sleep 2
        echo -n "."
    done
    
    echo -e "\n${GREEN}✅ Serviços prontos!${NC}"
}

pull_models() {
    echo -e "\n${YELLOW}📥 Fazendo pull dos modelos Ollama...${NC}"
    
    echo "  Modelo: llama2 (7B)"
    docker exec ollama ollama pull llama2 || echo "⚠️  Redownload necessário?"
    
    echo -e "\n  Modelo: mistral (7B) - Opcional"
    docker exec ollama ollama pull mistral || echo "⚠️  Mistral não foi baixado"
    
    echo -e "\n${GREEN}✅ Modelos prontos${NC}"
}

test_ollama() {
    echo -e "\n${YELLOW}🧪 Testando Ollama API...${NC}"
    
    # Teste de connectivity
    if curl -s http://localhost:11434/api/tags &>/dev/null; then
        echo -e "${GREEN}✅ Ollama acessível em http://localhost:11434${NC}"
        
        # Listar modelos
        echo -e "\n  Modelos disponíveis:"
        curl -s http://localhost:11434/api/tags | jq '.models[].name' 2>/dev/null || echo "  (Erro ao parsear JSON)"
    else
        echo -e "${RED}❌ Ollama não acessível!${NC}"
        return 1
    fi
}

test_openclaw() {
    echo -e "\n${YELLOW}🧪 Testando OpenClaw...${NC}"
    
    if docker ps | grep -q openclaw; then
        echo -e "${GREEN}✅ Container OpenClaw rodando${NC}"
        
        # Aguarde um pouco para o gateway iniciar
        sleep 5
        
        # Tente gerar um token
        TOKEN=$(docker exec openclaw openclaw doctor --generate-gateway-token 2>/dev/null | grep -oP '(?<=token=)[^\s&]+' | head -1) || true
        
        if [ -n "$TOKEN" ]; then
            echo -e "${GREEN}✅ Token gerado: $TOKEN${NC}"
            echo -e "   Dashboard: ${BLUE}http://localhost/?token=$TOKEN${NC}"
        else
            echo -e "${YELLOW}⚠️  Token não gerado (pode ser normal em primeira inicialização)${NC}"
        fi
    else
        echo -e "${RED}❌ Container OpenClaw não está rodando!${NC}"
        return 1
    fi
}

test_connectivity() {
    echo -e "\n${YELLOW}🔗 Testando conectividade OpenClaw → Ollama...${NC}"
    
    if docker exec openclaw curl -s http://ollama:11434/api/tags &>/dev/null; then
        echo -e "${GREEN}✅ OpenClaw consegue acessar Ollama${NC}"
    else
        echo -e "${RED}❌ OpenClaw NÃO consegue acessar Ollama!${NC}"
        echo "   Verifique as networks do Docker:"
        echo "   docker network inspect openclaw-docker_openclaw-net"
        return 1
    fi
}

show_status() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE}📊 Status dos Serviços${NC}"
    echo -e "${BLUE}================================================${NC}\n"
    
    docker-compose ps
    
    echo -e "\n${BLUE}📈 Uso de Recursos${NC}"
    echo "docker stats --no-stream"
    docker stats --no-stream 2>/dev/null || true
}

show_urls() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE}🌐 URLs de Acesso${NC}"
    echo -e "${BLUE}================================================${NC}\n"
    
    echo -e "${YELLOW}OpenClaw Dashboard:${NC}"
    TOKEN=$(docker exec openclaw openclaw doctor --generate-gateway-token 2>/dev/null | grep -oP '(?<=token=)[^\s&]+' | head -1) || TOKEN="<GERAR_TOKEN>"
    echo -e "  ${BLUE}http://localhost/?token=$TOKEN${NC}\n"
    
    echo -e "${YELLOW}Ollama API:${NC}"
    echo -e "  ${BLUE}http://localhost:11434${NC}\n"
    
    echo -e "${YELLOW}Open-WebUI (se ativado):${NC}"
    echo -e "  ${BLUE}http://localhost:3000${NC}\n"
    
    echo -e "${YELLOW}OpenClaw (via Nginx):${NC}"
    echo -e "  ${BLUE}http://localhost:80${NC}\n"
}

show_logs() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE}📜 Logs ${NC}"
    echo -e "${BLUE}================================================${NC}\n"
    
    echo -e "${YELLOW}Últimas 10 linhas - Ollama:${NC}"
    docker logs --tail=10 ollama 2>/dev/null || echo "Sem logs"
    
    echo -e "\n${YELLOW}Últimas 10 linhas - OpenClaw:${NC}"
    docker logs --tail=10 openclaw 2>/dev/null || echo "Sem logs"
    
    echo -e "\n${YELLOW}Últimas 10 linhas - Nginx:${NC}"
    docker logs --tail=10 openclaw-proxy 2>/dev/null || echo "Sem logs"
}

# ============ MENU PRINCIPAL ============

show_menu() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE}🎯 Opções${NC}"
    echo -e "${BLUE}================================================${NC}\n"
    
    echo "1) 🚀 Setup Completo (Recomendado)"
    echo "2) 🐳 Iniciar Containers"
    echo "3) 🛑 Parar Containers"
    echo "4) 🧪 Rodar Testes"
    echo "5) 📊 Status dos Serviços"
    echo "6) 🌐 Mostrar URLs de Acesso"
    echo "7) 📜 Ver Logs"
    echo "8) 🗑️  Limpar Tudo (CUIDADO!)"
    echo "9) 🚪 Sair"
    echo ""
    read -p "Escolha uma opção (1-9): " choice
    
    case $choice in
        1)
            check_docker
            check_docker_compose
            start_containers
            wait_for_services
            pull_models
            test_ollama
            test_openclaw
            test_connectivity
            show_status
            show_urls
            ;;
        2)
            start_containers
            wait_for_services
            show_status
            ;;
        3)
            echo -e "${YELLOW}Parando containers...${NC}"
            docker-compose down
            echo -e "${GREEN}✅ Containers parados${NC}"
            ;;
        4)
            echo -e "${YELLOW}Rodando testes...${NC}"
            test_ollama
            test_openclaw
            test_connectivity
            ;;
        5)
            show_status
            ;;
        6)
            show_urls
            ;;
        7)
            show_logs
            ;;
        8)
            echo -e "${RED}⚠️  CUIDADO! Isto vai remover containers, images e volumes!${NC}"
            read -p "Digite 'SIM' para confirmar: " confirm
            if [ "$confirm" = "SIM" ]; then
                docker-compose down -v
                echo -e "${GREEN}✅ Tudo removido${NC}"
            else
                echo "Cancelado"
            fi
            ;;
        9)
            echo -e "${GREEN}Até logo! 🦞${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida${NC}"
            show_menu
            ;;
    esac
}

# ============ EXECUÇÃO ============

if [ "$1" = "auto" ]; then
    # Modo automático (sem menu)
    check_docker
    check_docker_compose
    start_containers
    wait_for_services
    pull_models
    test_ollama
    test_openclaw
    test_connectivity
    show_status
    show_urls
elif [ "$1" = "logs" ]; then
    # Mostrar logs em tempo real
    docker-compose logs -f
else
    # Menu interativo
    show_menu
fi
