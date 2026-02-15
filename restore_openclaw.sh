#!/usr/bin/env bash
#
# Script de Restauração/Bootstrap para o Projeto OpenClaw Docker
# Versão: 1.2
# Data: 2026-02-13
# Autor: Atlas (com base na configuração do Ronaldo)
#
# Este script restaura o ambiente OpenClaw Docker a partir da configuração local.
# Requer Docker e Docker Compose instalados e o WSL com acesso ao drive E:\.
#

# --- Configurações Rigorosas de Shell ---
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error when substituting.
# -o pipefail: The return value of a pipeline is the status of the last command
#              to exit with a non-zero status, or zero if no command exited with
#              a non-zero status.
set -euo pipefail

# --- CONFIGURAÇÕES DO USUÁRIO (AJUSTE ESTES CAMINHOS CONFORME SEU AMBIENTE) ---
PROJECT_DIR="/mnt/e/openclaw-docker" # Caminho raiz do projeto no WSL
ENV_EXAMPLE_PATH="${PROJECT_DIR}/.env.example"
ENV_PATH="${PROJECT_DIR}/.env"
CUSTOM_CONFIG_PATH="${PROJECT_DIR}/config/custom-config.yaml"
DOCKERFILE_PATH="${PROJECT_DIR}/Dockerfile"
DOCKER_COMPOSE_PATH="${PROJECT_DIR}/docker-compose.yml"
ENTRYPOINT_SCRIPT_PATH="${PROJECT_DIR}/entrypoint.sh"
NGINX_CONF_SOURCE_DIR="${PROJECT_DIR}/nginx/conf.d" # Diretório fonte das configs do Nginx no host WSL
NGINX_SSL_SOURCE_DIR="${PROJECT_DIR}/nginx/ssl" # Diretório fonte dos SSLs no host WSL

# Diretórios de persistência de volume no host (onde os dados do Docker vão ficar)
RESTORE_LOG_DIR="${PROJECT_DIR}/logs" # Para logs de restauração
OPENCLAW_DATA_DIR="${PROJECT_DIR}/data"
OPENCLAW_LOGS_DIR="${PROJECT_DIR}/logs"


# Names do Docker Compose e Makefile
IMAGE_NAME="openclaw"
CONTAINER_NAME="openclaw"
NGINX_PROXY_CONTAINER_NAME="openclaw-proxy"

# --- FIM CONFIGURAÇÕES DO USUÁRIO ---

# ------ INICIALIZAÇÃO DE VARIÁVEIS DE LOGGING E CAMINHOS ------
# Garante que PROJECT_DIR está definido e é um diretório antes de continuar
if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  echo "ERRO: Diretório do projeto '$PROJECT_DIR' não está definido corretamente ou não existe."
  echo "Por favor, ajuste a variável 'PROJECT_DIR' no início deste script para o caminho correto do seu projeto no WSL."
  exit 1
fi

# Define o diretório de logs de restauração, cri AND check_command_status
RESTORE_LOG_DIR="${PROJECT_DIR}/logs"
mkdir -p "$RESTORE_LOG_DIR" || { echo "ERRO CRÍTICO: Não foi possível criar o diretório de logs de restauração em '$RESTORE_LOG_DIR'."; exit 1; }
RESTORE_LOG_FILE="${RESTORE_LOG_DIR}/restoration_log_$(date +'%Y%m%d_%H%M%S').log"

# Função de Logging: escreve no terminal E no arquivo de log
log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$RESTORE_LOG_FILE"
}

# Função de Verificação de Comando
check_command_status() {
  if [ $? -ne 0 ]; then
    log_message "ERRO: Falha ao executar o comando anterior. Verifique a saída detalhada acima e no arquivo de log '$RESTORE_LOG_FILE'."
    exit 1
  fi
}

# --- FUNÇÕES AUXILIARES ---
prompt_user_for_secrets() {
  log_message "Solicitando informações sensíveis para configurar o arquivo .env..."

  if [ ! -f "$ENV_EXAMPLE_PATH" ]; then
    log_message "ERRO: Arquivo .env.example não encontrado em '$ENV_EXAMPLE_PATH'."
    log_message "Por favor, certifique-se de que o arquivo .env.example está presente no diretório do projeto."
    exit 1
  fi

  log_message "Criando/atualizando o arquivo .env em '$ENV_PATH' a partir de '$ENV_EXAMPLE_PATH'..."
  cp "$ENV_EXAMPLE_PATH" "$ENV_PATH"
  check_command_status

  local USER_INPUT # Variável temporária para coletar input do usuário

  # Coleta interativa de secrets. Use '' (vazio) para manter o valor do .env.example.
  # Ao inserir um valor, ele sobrescreve o placeholder no arquivo .env.
  read -p "[INPUT NECESSÁRIO] GEMINI_API_KEY (deixe em branco para manter o do .env.example): " USER_INPUT
  if [ -n "$USER_INPUT" ]; then sed -i "s/^GEMINI_API_KEY=.*/GEMINI_API_KEY=${USER_INPUT}/" "$ENV_PATH"; fi

  read -p "[INPUT NECESSÁRIO] OPENROUTER_API_KEY (deixe em branco para manter): " USER_INPUT
  if [ -n "$USER_INPUT" ]; then sed -i "s/^OPENROUTER_API_KEY=.*/OPENROUTER_API_KEY=${USER_INPUT}/" "$ENV_PATH"; fi

  read -p "[INPUT NECESSÁRIO] BRAVE_API_KEY (deixe em branco para manter): " USER_INPUT
  if [ -n "$USER_INPUT" ]; then sed -i "s/^BRAVE_API_KEY=.*/BRAVE_API_KEY=${USER_INPUT}/" "$ENV_PATH"; fi

  read -p "[INPUT NECESSÁRIO] OPENCLAW_GATEWAY_TOKEN (default: 'dev-token', deixe em branco para manter): " USER_INPUT
  if [ -n "$USER_INPUT" ]; then sed -i "s/^OPENCLAW_GATEWAY_TOKEN=.*/OPENCLAW_GATEWAY_TOKEN=${USER_INPUT}/" "$ENV_PATH"; fi

  # Configuração do Modelo Padrão: Alinhado com 'openrouter/auto'
  log_message "Configurando modelo padrão para OpenClaw como 'openrouter/auto' no arquivo .env..."
  sed -i "s/^OPENCLAW_MODEL=.*/OPENCLAW_MODEL=openrouter\/auto/" "$ENV_PATH"
  # O sed pode precisar de escapes diferentes em alguns shells, re-aplicamos para garantir
  sed -i "s/^OPENCLAW_MODEL=.*/OPENCLAW_MODEL=openrouter\/auto/" "$ENV_PATH"

  # Configurações de Rede e Logging (geralmente do .env.example estão ok, mas confirmamos)
  read -p "[INPUT NECESSÁRIO] OPENCLAW_PORT (host port, default: 18790; deixe em branco para manter): " USER_INPUT
  if [ -n "$USER_INPUT" ]; then sed -i "s/^OPENCLAW_PORT=.*/OPENCLAW_PORT=${USER_INPUT}/" "$ENV_PATH"; fi

  read -p "[INPUT NECESSÁRIO] LOG_LEVEL (default: INFO; use DEBUG para mais detalhes): " USER_INPUT
  if [ -n "$USER_INPUT" ]; then sed -i "s/^LOG_LEVEL=.*/LOG_LEVEL=${USER_INPUT}/" "$ENV_PATH"; fi

  log_message "Arquivo .env configurado com suas entradas. Lembre-se de NÃO commitar este arquivo para o Git."
}

# --- EXECUÇÃO PRINCIPAL ---

log_message "--- Iniciando Script de Restauração/Bootstrap do Projeto OpenClaw Docker ---"

# 0. Preparar ambiente e diretórios de persistência
log_message "Verificando a existência dos arquivos e diretórios essenciais..."
[ -d "$PROJECT_DIR" ] || { log_message "ERRO: Diretório do projeto '$PROJECT_DIR' não encontrado. Verifique e ajuste a variável PROJECT_DIR no script."; exit 1; }
[ -f "$DOCKERFILE_PATH" ] || { log_message "ERRO: Dockerfile não encontrado em '$DOCKERFILE_PATH'."; exit 1; }
[ -f "$DOCKER_COMPOSE_PATH" ] || { log_message "ERRO: docker-compose.yml não encontrado em '$DOCKER_COMPOSE_PATH'."; exit 1; }
[ -f "$ENTRYPOINT_SCRIPT_PATH" ] || { log_message "ERRO: entrypoint.sh não encontrado em '$ENTRYPOINT_SCRIPT_PATH'."; exit 1; }
[ -f "$ENV_EXAMPLE_PATH" ] || { log_message "ERRO: .env.example não encontrado em '$ENV_EXAMPLE_PATH'."; exit 1; }
[ -f "$CUSTOM_CONFIG_PATH" ] || { log_message "AVISO: custom-config.yaml não encontrado em '$CUSTOM_CONFIG_PATH'. O OpenClaw pode usar configurações padrão ou as do .env."; }

# Garantir que os diretórios de volume existam no host
log_message "Garantindo que os diretórios de volume no host existam..."
mkdir -p "$OPENCLAW_DATA_DIR" && check_command_status
mkdir -p "$OPENCLAW_LOGS_DIR" && check_command_status

# Diretórios de Nginx são mapeados diretamente via docker-compose.yml, não precisa criar no host se o docker-compose gerencia.
# Apenas avisamos se a origem não for encontrada no host.
[ -d "$NGINX_CONF_SOURCE_DIR" ] || log_message "AVISO: Diretório de configuração Nginx fonte '$NGINX_CONF_SOURCE_DIR' não encontrado no host. Verifique o mapeamento no docker-compose.yml."
[ -d "$NGINX_SSL_SOURCE_DIR" ] || log_message "AVISO: Diretório de SSL Nginx fonte '$NGINX_SSL_SOURCE_DIR' não encontrado no host. Verifique o mapeamento no docker-compose.yml."
log_message "Diretórios de volume preparados."

# 1. Preparar o arquivo .env
prompt_user_for_secrets

# 2. Construir a imagem Docker (se necessário)
log_message "Verificando a existência da imagem Docker '$IMAGE_NAME'..."
if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
  log_message "Imagem '$IMAGE_NAME' não encontrada. Construindo a imagem Docker a partir de '$DOCKERFILE_PATH'..."
  cd "$PROJECT_DIR"
  docker build -t "$IMAGE_NAME" .
  check_command_status
  log_message "Imagem '$IMAGE_NAME' construída com sucesso."
else
  log_message "Imagem Docker '$IMAGE_NAME' já existe. Skipeando build."
fi

# 3. Iniciar os serviços com Docker Compose
log_message "Iniciando os serviços usando docker-compose.yml..."
cd "$PROJECT_DIR" # Garantir que rodamos de onde o docker-compose.yml está
# Usar --env-file para carregar variáveis do .env para a configuração do compose
docker-compose --env-file "$ENV_PATH" up -d
check_command_status
log_message "Serviços levantados com docker-compose."

# 4. Verificar o status dos containers
log_message "Verificando o status dos containers..."
docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" --no-trunc | tee -a "$RESTORE_LOG_FILE"
docker ps --filter "name=${NGINX_PROXY_CONTAINER_NAME}" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" --no-trunc | tee -a "$RESTORE_LOG_FILE"

check_command_status

# 5. Testar a conexão do OpenClaw (usando lógica do Makefile para pegar a porta)
log_message "Executando teste de saúde do OpenClaw..."
# Tenta obter a porta do host do .env, depois do .env.example, então usa um padrão
HOST_PORT=$(grep "^OPENCLAW_PORT=" "$ENV_PATH" | cut -d'=' -f2)
if [ -z "$HOST_PORT" ]; then
  HOST_PORT=$(grep "^PORT_HOST=" "$ENV_EXAMPLE_PATH" | cut -d'=' -f2) # Tenta do arquivo de exemplo
  if [ -z "$HOST_PORT" ]; then
    HOST_PORT=18790 # Valor padrão se nada for encontrado
  fi
fi

# Loop para verificar a saúde do serviço
for i in {1..5}; do
  if curl -s "http://localhost:${HOST_PORT}/health" > /dev/null; then
    log_message "✅ Saúde do OpenClaw OK em http://localhost:${HOST_PORT}/health"
    break
  else
    if [ "$i" -eq 5 ]; then
      log_message "❌ Falha no teste de saúde do OpenClaw após 5 tentativas. Verifique os logs do container '$CONTAINER_NAME':"
      docker logs "$CONTAINER_NAME" 2>&1 | tee -a "$RESTORE_LOG_FILE"
    else
      log_message "Tentativa $i/5 falhou. Aguardando 5 segundos..."
      sleep 5
    fi
  fi
done

# 6. Ativar plugin Google Antigravity (se o usuário optar)
log_message "Verificando ativação do plugin 'google-antigravity-auth'..."
ENTRYPOINT_MODIFIED=false
if [ -f "$ENTRYPOINT_SCRIPT_PATH" ] && grep -qE '^#\s*openclaw plugins enable google-antigravity-auth' "$ENTRYPOINT_SCRIPT_PATH"; then
  log_message "Plugin 'google-antigravity-auth' está comentado no entrypoint.sh."
  read -p "[INPUT OPCIONAL] Deseja descomentar e ativar o plugin 'google-antigravity-auth' agora? (s/N): " USER_INPUT_PLUGIN
  if [[ "$USER_INPUT_PLUGIN" =~ ^[Ss]$ ]]; then
    # Substitui o comentário pela linha ativa
    sed -i 's/^#\s*openclaw plugins enable google-antigravity-auth/openclaw plugins enable google-antigravity-auth/' "$ENTRYPOINT_SCRIPT_PATH"
    ENTRYPOINT_MODIFIED=true
    log_message "Plugin 'google-antigravity-auth' será ativado na próxima inicialização do container."
  fi
else
  # Verifica se o plugin já está ativo ou se o entrypoint.sh não existe
  if [ -f "$ENTRYPOINT_SCRIPT_PATH" ]; then
    log_message "Plugin 'google-antigravity-auth' já está descomentado no entrypoint.sh ou não estava presente."
  else
    log_message "AVISO: entrypoint.sh não encontrado em '$ENTRYPOINT_SCRIPT_PATH'. Não foi possível verificar/modificar o plugin."
  fi
fi

# Instruções de reconstrução se o entrypoint.sh foi modificado
if [ "$ENTRYPOINT_MODIFIED" = true ] && [ -f "$DOCKERFILE_PATH" ] && [ -f "$ENV_PATH" ]; then
  log_message "\nATENÇÃO: O arquivo entrypoint.sh foi modificado para ativar o plugin."
  log_message "Para que esta mudança tenha efeito, você precisará:"
  log_message "1. Reconstruir a imagem Docker: Execute 'cd ${PROJECT_DIR} && docker build -t ${IMAGE_NAME} .'"
  log_message "2. Reiniciar os containers: Execute 'cd ${PROJECT_DIR} && docker-compose --env-file ${ENV_PATH} down && docker-compose --env-file ${ENV_PATH} up -d'"
fi

# 7. Mensagem final e instruções de próximos passos
OPENCLAW_MODEL=$(grep "^OPENCLAW_MODEL=" "$ENV_PATH" | cut -d'=' -f2 || echo "openrouter/auto")
if [ -z "${OPENCLAW_MODEL:-}" ]; then OPENCLAW_MODEL="openrouter/auto"; fi

log_message "\n--- Restauração/Bootstrap do Projeto OpenClaw Docker Concluída ---"
log_message "O ambiente foi configurado com os arquivos fornecidos e os serviços foram iniciados."
log_message "\nRECOMENDAÇÕES IMPORTANTES:"
log_message "1. Acesse o OpenClaw: Navegue para http://localhost:${HOST_PORT}. Você também pode usar 'make dashboard' se o Makefile estiver em $(pwd)/Makefile."
log_message "2. Monitoramento: Use 'make logs' ou 'docker logs ${CONTAINER_NAME}' para ver os logs em tempo real."
log_message "3. Depuração: Acesse o container com 'make exec' ou 'docker exec -it ${CONTAINER_NAME} bash'."
log_message "4. Restauração de Dados Persistentes: Para restaurar seu histórico e configurações (MEMORY.md, etc.), copie o conteúdo do seu backup para '${OPENCLAW_DATA_DIR}' e '${OPENCLAW_LOGS_DIR}'. Em seguida, reinicie os containers (ex: 'make stop && make start' ou 'docker-compose down && docker-compose up -d' na pasta do projeto)."
log_message "5. Segurança do .env: NUNCA commite o arquivo '.env' gerado para o Git. Certifique-se de que ele esteja adicionado ao seu arquivo .gitignore."
log_message "6. Mapeamento de Volume E:\\: Tenha cautela com o mapeamento total do drive E:\\ ('E:\\:/mnt/e-drive') para o container. Para maior segurança, considere mapear apenas diretórios específicos se possível (ex: 'E:/openclaw-docker/data:/home/openclaw/.config/openclaw')."
log_message "7. Autonomia e Modelos: O modelo padrão '${OPENCLAW_MODEL}' está configurado no .env. Seu custom-config.yaml também aponta 'openrouter/auto' como modelo padrão para agentes. Verifique se as chaves de API necessárias (OpenRouter, Gemini, etc.) estão corretas no .env."
log_message "\nLogs completos da restauração podem ser encontrados em:\n$RESTORE_LOG_FILE"
