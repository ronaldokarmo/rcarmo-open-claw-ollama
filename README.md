# OpenClaw Docker Project

Este projeto fornece um ambiente containerizado robusto para executar o OpenClaw, uma plataforma de agentes de IA. Ele utiliza Docker e Docker Compose para orquestrar a aplicação principal e um proxy reverso Nginx, facilitando a configuração, o deployment e a gestão de logs e dados persistentes.

## Funcionalidades

- **Orquestração via Docker Compose**: Gerenciamento simplificado de containers.
- **Proxy Reverso Nginx**: Acesso facilitado e configuração de SSL (se necessário).
- **Scripts de Automação**: Scripts para setup inicial (`setup.sh`), restauração (`restore_openclaw.sh`) e monitoramento (`monitor.sh`).
- **Persistência de Dados**: Volumes configurados para persistir configurações, chaves e memória dos agentes.
- **Configuração Flexível**: Uso de arquivo `.env` para gerenciamento de chaves de API e configurações do ambiente.
- **Modelos Otimizados**: Suporte a modelos locais e em nuvem com aliases pré-configurados.

## Modelos e Especialidades

| Alias | Modelo (ID OpenRouter) | Especialidade | Pontos Fortes |
| :--- | :--- | :--- | :--- |
| **flash** | `google/gemini-2.0-flash-001` | Velocidade & Visão | Resposta quase instantânea. Excelente para analisar screenshots de bugs e logs extensos de automação. |
| **sonnet** | `anthropic/claude-3.5-sonnet` | Codificação (Coding) | O "Gold Standard" para gerar scripts Playwright, Appium e lógica complexa de integração no Home Assistant. |
| **r1** | `deepseek/deepseek-r1` | Raciocínio Lógico | Modelo de "Chain of Thought". Ideal para debugar erros de lógica complexos ou arquitetar redes IoT do zero. |
| **chat** | `deepseek/deepseek-chat` | Custo-Benefício | Ótimo para conversas gerais e tarefas repetitivas. Extremamente barato e muito capaz (V3). |
| **fast** | `ollama/llama3.1-fast` | Privacidade Local | Roda 100% na sua Orange Pi 5. Perfeito para processar dados sensíveis da sua casa sem sair da rede local. |

## Pré-requisitos

Antes de começar, certifique-se de ter instalado em sua máquina:

- [Docker Desktop](https://www.docker.com/products/docker-desktop) (com integração WSL 2 se estiver no Windows)
- [Docker Compose](https://docs.docker.com/compose/install/) (geralmente incluído no Docker Desktop)
- [Node.js 22+](https://nodejs.org) (Necessário para o build do OpenClaw dentro do container)
- Um terminal Bash (Git Bash, WSL, ou terminal nativo Linux/Mac)

## Instalação e Configuração

Você pode configurar o projeto utilizando os scripts de automação ou manualmente.

### Método 1: Instalação Automática (Recomendado)

O script `setup.sh` verifica as dependências, cria o arquivo `.env` (se não existir), solicita sua chave de API do Gemini e inicia os serviços.

```bash
./setup.sh
```

### Método 2: Instalação Manual

1.  **Clone o repositório (se ainda não o fez):**
    (Se estiver usando este projeto localmente, pule para o próximo passo).

2.  **Configuração do Ambiente:**
    Copie o arquivo de exemplo `.env.example` para `.env`:
    ```bash
    cp .env.example .env
    ```

3.  **Edite o arquivo `.env`:**
    Abra o arquivo `.env` e adicione suas chaves de API e configurações desejadas.
    ```properties
    GEMINI_API_KEY=sua_chave_aqui
    OPENROUTER_API_KEY=sua_chave_aqui
    # ... outras chaves
    OPENCLAW_MODEL=openrouter/auto
    LOG_LEVEL=INFO
    ```

4.  **Construir e Iniciar:**
    ```bash
    docker-compose build
    docker-compose up -d
    ```

### Método 3: Restauração / Bootstrap

Se você estiver restaurando um ambiente ou precisando de uma configuração mais avançada (incluindo verificação de volumes no host), use o script de restauração:

```bash
./restore_openclaw.sh
```

## Estrutura do Projeto

- **`config/`**: Arquivos de configuração do OpenClaw (ex: `custom-config.yaml`).
- **`data/`**: Dados persistentes do OpenClaw (memória, sessões). Mapeado para `/home/openclaw/.config/openclaw`.
- **`logs/`**: Logs da aplicação e de restauração.
- **`nginx/`**: Configurações (`conf.d`) e certificados (`ssl`) para o proxy reverso.
- **`scripts`**:
    - `setup.sh`: Script de inicialização rápida.
    - `restore_openclaw.sh`: Script robusto de verificação e restauração.
    - `monitor.sh`: Script para visualizar status e logs rapidamente.
    - `entrypoint.sh`: Script executado dentro do container ao iniciar.

## Uso

### Acessar o Dashboard

Após iniciar os containers, o OpenClaw estará acessível em:

- **Via Nginx (Proxy):** `http://localhost` (Porta 80)
- **Direto no Container:** `http://localhost:18790` (ou a porta definida em `OPENCLAW_PORT` no `.env`)

### Monitoramento e Logs

Para verificar o status dos containers e ver os logs em tempo real:

**Usando o script de monitoramento:**
```bash
./monitor.sh
```

**Usando comandos Docker:**
```bash
# Ver logs em tempo real
docker-compose logs -f

# Ver logs apenas do serviço openclaw
docker-compose logs -f openclaw
```

### Parar a Aplicação

Para parar e remover os containers (mantendo os dados dos volumes):

```bash
docker-compose down
```

Para parar e remover volumes (CUIDADO: isso apaga dados persistentes não salvos no host):
```bash
docker-compose down -v
```

## Acesso ao Container (Shell)

Para executar comandos diretamente dentro do container do OpenClaw:

```bash
docker exec -it openclaw bash
```
Ou para gerar um token de gateway, por exemplo:
```bash
docker exec -it openclaw openclaw doctor --generate-gateway-token
```

## Solução de Problemas

-   **Porta em uso:** Se encontrar erros de "port already allocated", verifique se não há outros serviços rodando nas portas 80 ou 18790. Você pode alterar as portas no `docker-compose.yml` ou `.env`.
-   **Permissões e Volumes:** Se o comando `openclaw` não for encontrado ou os plugins não carregarem, verifique se os volumes `./openclaw-data` ou `./node_modules` no `docker-compose.yml` não estão sobrescrevendo a instalação interna. Recentemente desativamos esses mounts por padrão para garantir estabilidade.
-   **Quebras de Linha (CRLF vs LF):** Se o container falhar com erros de sintaxe (ex: `\r: command not found`), execute o comando `wsl dos2unix entrypoint.sh` ou `sed -i 's/\r$//' entrypoint.sh` no seu terminal Bash para corrigir as quebras de linha Windows.
-   **Variáveis de Ambiente:** Se as chaves de API não estiverem funcionando, verifique se elas foram salvas corretamente no arquivo `.env` e se o container foi recriado (`docker build --no-cache` seguido de `docker compose up -d`) após as alterações.

---
*Projeto configurado para ambiente de desenvolvimento e produção local.*
