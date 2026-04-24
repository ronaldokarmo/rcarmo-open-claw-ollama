# Plano de Melhorias do OpenClaw Docker

## 📋 Contexto

O projeto OpenClaw é uma plataforma de rede de agentes LLM que requer otimizações contínuas em performance, segurança, observabilidade e experiência do usuário.

---

## 🎯 Melhoria 1: Dockerfile Multi-stage

### Problema
O Dockerfile atual não está otimizado para produção, resultando em imagem grande e vulnerável.

### Solução

#### Criar imagem base otimizada:
```dockerfile
# Stage 1: Build (não publicada)
FROM python:3.11-slim-bookworm AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

#### Criar imagem final com camadas otimizadas:
FROM python:3.11-slim-bookworm AS final

LABEL maintainer="openclaw@example.com"
LABEL version="1.0"

# Sistema de arquivos otimizado
RUN mkdir -p /app /data /logs && \
    chown -R 1000:1000 /app /data /logs

# Instalar dependências mínimas
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar dependências do stage builder
COPY --from=builder /root/.local /root/.local
COPY --from=builder /root/.local/bin /root/.local/bin
COPY --from=builder /root/.local/lib /root/.local/lib
COPY --from=builder /root/.cache /root/.cache
COPY . .

# Instalar ferramentas de monitoramento (opcionais)
RUN apt-get install -y --no-install-recommends \
    uv \
    && rm -rf /var/lib/apt/lists/*

# Instalar pip user local
ENV PATH="/root/.local/bin:$PATH"
ENV PYTHONPATH="/root/.local/lib/python3.11/site-packages"

ENV HOME=/home/app
ENV PYTHONPATH=/app

WORKDIR /app
COPY . .
COPY --from=builder /root/.cache /root/.cache

# Criar usuário não-root
RUN adduser --disabled-password --gecos '' appuser && \
    usermod -aG docker appuser && \
    chown -R appuser:appuser /app && \
    chmod -R 755 /app

USER appuser

# Instalar uv globalmente para builds mais rápidos
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# Instalar dependências em modo otimizado
RUN pip install --upgrade --no-cache-dir uv

# Configurar memória (verificar se necessário para agentes)
ENV OLLAMA_HOST=0.0.0.0
ENV AGENT_ENV=production

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD uvicorn openclaw_api:app --host 0.0.0.0 --port $PORT || exit 1

# Entrypoint
CMD ["uvicorn", "openclaw_api:app", "--host", "0.0.0.0", "--port", "$PORT"]
```

**Impacto:**
- Redução de ~70% no tamanho da imagem (de ~500MB para ~150MB)
- Menor superfície de ataque (mínimas de dependências)
- Melhor performance de cold start

---

## 🎯 Melhoria 2: Otimização de Agentes

### Agentes para Otimizar

#### 1. **Atom** (Agente principal de coordenação)
- Implementar cache de resultados de consultas
- Adicionar rate limiting para evitar sobrecarga
- Criar fila de mensagens assíncrona

#### 2. **OpenClaw** (Agente central)
- Otimizar prompts de sistema para reduzir tokens
- Implementar circuit breaker para chamadas de API externas
- Adicionar fallback automático

#### 3. **Llama-70B** (Agente de análise)
- Implementar quantização (GGUF, EXL2)
- Configurar GPU sharing via vLLM
- Adicionar layer caching

#### 4. **Tutor English** e outros agentes
- Implementar streaming para responses
- Adicionar compressão de logs
- Otimizar tamanho de contexto

---

## 🎯 Melhoria 3: Sistema de Memória Estruturado

### Estrutura Atual (Identificada)
```
data/.openclaw/workspace/memory/
├── MEMORY.md
├── 2026-02-12.md
├── 2026-02-11.md
└── ...
```

### Estrutura Otimizada

#### Criar indexação automática:
```markdown
# MEMORY.md - Índice de Memória

## 📂 Memória por Área

### User/Perfil do Usuário
- [user_profile.md](memory/user_profile.md) - Informações sobre o usuário
- [preferences.md](memory/preferences.md) - Preferências configuradas

### Project/Estrutura do Projeto
- [project_ecosystem.md](memory/project_ecosystem.md) - Arquitetura do projeto
- [architecture.md](memory/architecture.md) - Diagramas de arquitetura
- [roadmap.md](memory/roadmap.md) - Roadmap de desenvolvimento

### Feedback/Guidelines
- [feedback.md](memory/feedback.md) - Correções e feedbacks do usuário
- [standards.md](memory/standards.md) - Padrões de código

### Technical/Técnico
- [docker-optimizations.md](memory/docker-optimizations.md) - Otimizações Docker
- [database.md](memory/database.md) - Configurações de banco de dados
- [api-docs.md](memory/api-docs.md) - Documentação de API

### Project/Estrutura do Projeto (Estruturado)
- [project-structure.md](memory/project-structure.md) - Estrutura de arquivos do projeto
- [components.md](memory/components.md) - Componentes principais
```

**Benefícios:**
- Busca rápida por categoria
- Indexação por metadados
- Versionamento por data

---

## 🎯 Melhoria 4: Observabilidade e Monitoring

### Implementar Stack completo

#### 1. Prometheus + Grafana
```yaml
# Adicionar ao docker-compose.yml
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - prometheus_data:/prometheus
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=grafana
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
    depends_on:
      - prometheus

volumes:
  prometheus_data:
  grafana_data:
```

#### 2. Health Check Endpoints
```python
# Em openclaw_api.py
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "uptime": process.cpu_times().user + process.cpu_times().system,
        "memory": psutil.Process().memory_info().rss / 1024 ** 2
    }

@app.get("/agents/status")
async def get_agent_status():
    agents = get_all_agents()
    return {
        "agents": [
            {
                "id": agent.id,
                "type": agent.__class__.__name__,
                "status": "active",
                "last_active": datetime.now().isoformat()
            }
            for agent in agents
        ]
    }

@app.get("/logs")
async def get_logs(request: Request):
    level = request.query_params.get("level", "INFO")
    lines = request.query_params.get("lines", "50")
    return read_log_file(f"/logs/app.log", lines=int(lines), level=level)
```

#### 3. Logging Estruturado
```python
# Em main.py
import logging
import json
from datetime import datetime

def get_logger(name):
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)
    handler = logging.FileHandler("/logs/app.log")
    formatter = logging.Formatter(
        '{"timestamp": "%(asctime)s", "level": "%(levelname)s", "message": "%(message)s"}',
        datefmt='%Y-%m-%dT%H:%M:%S'
    )
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    return logger

def json_logger(level, message):
    logger.info(f"{level}: {message}", extra={'level': level})
```

---

## 🎯 Melhoria 5: Configuração de Ambiente (.env)

### Arquivo .env Otimizado

```env
# ================================
# OpenClaw - Ambiente de Produção
# ================================

# ================================
# Docker & Container
# ================================
# Container ID único para rastreamento
CONTAINER_ID=4c91805617538e8f

# Memória alocada para o container (16GB)
CONTAINER_MEMORY=16G

# ================================
# Agentes & API
# ================================
# Portas dos agentes
AGENT_PORT=5111
AGENT_HOST=0.0.0.0

# Portas de API
AGENTS_API_PORT=5112
AGENTS_API_HOST=0.0.0.0
AGENTS_PORT=8000
API_PORT=8001
AGENTS_API_PORT=8002

# URLs das APIs (Llama, Ollama, etc.)
AGENTS_URLS_API_LLM_URLS=http://172.18.0.2:11434
AGENTS_URLS_API_LLM_API_KEY=ollama

# ================================
# Observabilidade
# ================================
# Monitoramento e logs
PROMETHEUS_PORT=9090
GRAFANA_PORT=3001
LOG_LEVEL=INFO

# ================================
# Volumes & Dados
# ================================
# Caminho dos volumes
OBSIDIAN_VAULT_PATH=./vault
OBSIDIAN_VAULT_PATH=/vault
VAULT_PATH=/vault

# ================================
# Agentes
# ================================
AGENT_MODEL=llama3.2:3b
AGENT_MODEL_2=llama3.1:8b
AGENT_MODEL_3=llama3.2:1b

# ================================
# Observabilidade Engineer
# ================================
OBSIDIAN_VAULT_PATH=/vault
```

---

## 🎯 Melhoria 6: Segurança

### Checklist de Segurança

#### 1. Não-root
- [x] Criar usuário `appuser`
- [x] Definir permissões mínimas

#### 2. Secrets Management
```yaml
# Adicionar ao docker-compose.yml
services:
  agent-main:
    # Não expor secrets no ambiente
    environment:
      - API_KEY=${AGENT_API_KEY}
    # Usar secrets do Docker
    secrets:
      - api_key
    # Mount secrets como arquivo
    volumes:
      - ./secrets:/run/secrets:ro

secrets:
  api_key:
    file: ./secrets/api_key.txt
```

#### 3. Network Segmentation
```yaml
networks:
  agent_network:
    driver: bridge
    internal: true  # Network interna para agentes
    ipam:
      config:
        - subnet: 172.28.0.0/16

  api_network:
    driver: bridge
    external: true  # Network externa para API
```

#### 4. Health Check
- [x] Adicionar health check ao Dockerfile
- [ ] Implementar retry logic no client

#### 5. Resource Limits
```yaml
services:
  agent-main:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 4G
```

---

## 🎯 Melhoria 7: Scripts de Operação

### scripts/

#### 1. deploy.sh
```bash
#!/bin/bash
# Script de deploy com rollback automático

set -e

echo "🔧 Deploy do OpenClaw..."

# Backup da configuração atual
if [ -f docker-compose.backup.$(date +%Y%m%d%H%M%S) ]; then
    echo "⚠️  Backup anterior existente, não sobrescrevendo..."
else
    docker-compose down
    docker-compose up -d
fi

# Monitoramento inicial
echo "📊 Monitorando startup dos containers..."
for i in {1..10}; do
    if docker-compose ps | grep -q "Up"; then
        echo "✅ Containers iniciados com sucesso"
        break
    fi
    echo "⏳ Esperando containers... ($i/10)"
    sleep 5
done
```

#### 2. backup.sh
```bash
#!/bin/bash
# Script de backup

set -e

BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup de volumes
echo "📦 Fazendo backup dos volumes..."
tar -czf $BACKUP_DIR/volumes-$DATE.tar.gz \
    -C . \
    data/vault \
    data/memory

# Backup de configuração
tar -czf $BACKUP_DIR/docker-$DATE.tar.gz \
    docker-compose.yml \
    .env

# Manter apenas últimos 7 backups
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "✅ Backup criado: $BACKUP_DIR/volumes-$DATE.tar.gz"
```

#### 3. cleanup.sh
```bash
#!/bin/bash
# Limpeza de recursos

echo "🧹 Limpando recursos..."

# Remover containers parados
docker-compose rm -f -s $(docker-compose ps -q)

# Limpar volumes não usados
docker-compose prune

# Limpar imagens não usadas
docker image prune -af
```

---

## 🎯 Melhoria 8: Documentação Técnica

### Estrutura da Documentação

```
docs/
├── architecture/
│   ├── docker/
│   │   ├── docker-compose.md
│   │   ├── Dockerfile.md
│   │   └── volumes.md
│   ├── agents/
│   │   ├── atom.md
│   │   ├── openclaw.md
│   │   ├── llama-70b.md
│   │   └── tutor-english.md
│   └── deployment/
│       ├── docker-compose.md
│       └── docker.md
├── api/
│   ├── endpoints/
│   │   ├── /agents.md
│   │   ├── /chat.md
│   │   └── /knowledge/
│   └── responses/
├── logs/
│   ├── structure.md
│   └── debugging.md
└── troubleshooting/
    ├── common-issues.md
    └── performance.md
```

---

## 📊 Priorização

### P0 - Crítico (Fazer imediata)
- [ ] Otimizar Dockerfile (multistage)
- [ ] Implementar health checks
- [ ] Melhorar observabilidade (logs estruturados)
- [ ] Criar scripts de operação

### P1 - Alto (Fazer esta semana)
- [ ] Implementar Prometheus + Grafana
- [ ] Otimizar agentes (cache, streaming)
- [ ] Melhorar .env e secrets
- [ ] Criar documentação técnica

### P2 - Médio (Fazer na próxima sprint)
- [ ] Implementar circuit breakers
- [ ] Otimizar prompts de sistema
- [ ] Melhorar estrutura de memória
- [ ] Criar scripts de backup

### P3 - Baixo (Backlog)
- [ ] Monitoramento avançado (OpenTelemetry)
- [ ] Testes de carga
- [ ] Benchmark de performance

---

## 📈 Métricas de Sucesso

### Performance
- [ ] Tempo de resposta < 3s
- [ ] Uptime > 99.9%
- [ ] Cache hit rate > 80%

### Segurança
- [ ] Nenhuma vulnerabilidade crítica
- [ ] Secrets não expostos
- [ ] Network segmentation completa

### Observabilidade
- [ ] 100% de health checks passando
- [ ] Logs estruturados em 100% das requisições
- [ ] Métricas disponíveis no Prometheus

---

## 🚀 Próximos Passos

1. **I** Implementar P0 imediato
2. **M** Monitorar impacto nas métricas
3. **R** Refinar com feedback
4. **I** Iterar sobre P1

**Duração Estimada: 4-8 horas**

**Dependências:**
- Docker Desktop
- Prometheus
- Grafana
