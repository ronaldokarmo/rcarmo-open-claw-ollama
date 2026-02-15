# OpenClaw Docker Project

Este projeto configura um ambiente OpenClaw usando Docker, incluindo integrações com diversos modelos de IA.

## Pré-requisitos

- Docker
- Docker Compose

## Instalação e Execução

### Construir e Iniciar

Para construir e iniciar os containers em segundo plano:

```bash
docker-compose up -d --build
```

Para acompanhar os logs:

```bash
docker-compose logs -f
```

### Parar

Para parar e remover os containers:

```bash
docker-compose down
```

## Acesso

O painel do OpenClaw estará acessível via web. Verifique os logs para obter o token de acesso inicial ou execute:

```bash
docker exec -it openclaw openclaw doctor --generate-gateway-token
```

## Comandos Úteis

### Reconstruir do Zero

```bash
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

### Acessar o Container

```bash
docker exec -it openclaw bash
```

## Configuração de Modelos

Para configurar modelos (ex: Gemini, OpenRouter), utilize a CLI do OpenClaw dentro do container ou a interface web.

Exemplo para Gemini:

```bash
openclaw config add-model '{
  "name": "Gemini Flash",
  "provider": "google",
  "model": "gemini-2.5-flash",
  "api_key": "SUA_CHAVE_AQUI"
}'
```

---
*Para mais detalhes, consulte a documentação oficial do OpenClaw.*
