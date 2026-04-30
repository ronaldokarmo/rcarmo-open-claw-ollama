# Plano de Melhorias do OpenClaw Docker

> **Revisão Crítica:** `2026-04-25`
> Plano auditado contra o estado real do projeto. Itens já implementados foram movidos para o [Plano de Limpeza](#-plano-de-limpeza--consolidação). Itens incorretos foram removidos.

---

## 📋 Contexto

O projeto OpenClaw é uma plataforma de rede de agentes LLM baseada em **Node.js** (não Python), rodando via `openclaw gateway` num container Alpine. O ambiente atual conta com:

- `openclaw` container (Node.js 20 Alpine, multi-stage)
- `ollama` container (GPU NVIDIA RTX 4060, 8GB VRAM)
- `nginx` container (proxy reverso — **sem configuração ativa**)
- `hermes` container (agente auxiliar — **instalação via curl em runtime, sem imagem própria**)
- Plugin `memory-wiki` integrado com Obsidian Vault (`E:/obsidian/OpenClaw`)
- Agentes ativos em `openclaw.json`: `main`, `tutor-english`, `tutor-iot`, `prompt-engineer`

---

## 🚨 MELHORIAS P0 — CRÍTICO (Problemas Ativos)

### P0-1: Modelos Cloud causando erro 403

**Diagnóstico:**
O `openclaw.json` define como modelo primário `ollama/kimi-k2.6:cloud` com fallback para `ollama/kimi-k2.5:cloud`. Esses modelos estão registrados sob o provider `ollama` mas são serviços de nuvem que **requerem assinatura paga** — causando erro `403: this model requires a subscription` em produção.

**Raiz do problema em `openclaw.json`:**
```json
"defaults": {
  "model": {
    "primary": "ollama/kimi-k2.6:cloud",   // ← QUEBRADO: requer assinatura
    "fallbacks": [
      "ollama/kimi-k2.5:cloud",            // ← QUEBRADO: requer assinatura
      "ollama/llama3.1:8b"                 // ← OK: modelo local
    ]
  }
}
```

**Correção:**
```json
"defaults": {
  "model": {
    "primary": "ollama/qwen3.5:9b",
    "fallbacks": [
      "ollama/llama3.1:8b",
      "groq/llama-3.3-70b-versatile"
    ]
  }
}
```

**Correção do agente `main`:**
```json
{ "id": "main", "model": "ollama/qwen3.5:9b" }
```

**Impacto:** Elimina todos os erros 403 em produção. Bloqueia o uso do sistema atualmente.

---

### P0-2: Path do Obsidian hardcoded no docker-compose

**Diagnóstico:**
O `docker-compose.yml` linha 73 monta o vault do Obsidian com path absoluto do Windows:
```yaml
- E:/obsidian/OpenClaw:/home/openclaw/obsidian:rw
```
A variável `OBSIDIAN_VAULT_HOST=E:/obsidian/OpenClaw` **já existe no `.env`** mas não está sendo usada no compose. Isso impede que o projeto rode em qualquer outro ambiente.

**Correção no `docker-compose.yml`:**
```yaml
- ${OBSIDIAN_VAULT_HOST}:/home/openclaw/obsidian:rw
```

**Impacto:** Portabilidade. Qualquer pessoa clona e configura apenas o `.env`.

---

### P0-3: Nginx sem configuração — Proxy inativo

**Diagnóstico:**
O container `nginx` está no `docker-compose.yml` expondo as portas 80 e 443, mas:
- `nginx/conf.d/` está **completamente vazia** (nenhum arquivo `.conf`)
- `nginx/ssl/` sem certificados
- O Nginx roda com configuração padrão, **sem rotear nada para o OpenClaw** na porta 18790

Isso significa que **nginx não está fazendo proxy reverso** — o acesso externo vai direto na porta 18790, sem CORS, sem HTTPS, sem rate limiting.

**Ação:**
- [ ] Criar `nginx/conf.d/openclaw.conf` com upstream para `openclaw:18790`
- [ ] Configurar HTTPS com certificado auto-assinado (`nginx/ssl/`)
- [ ] Ou desativar o nginx no compose se não for usado

**Exemplo de configuração mínima:**
```nginx
upstream openclaw_upstream {
    server openclaw:18790;
}

server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://openclaw_upstream;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

### P0-4: Agente `prompt-engineer` com modelo inexistente

**Diagnóstico:**
O `openclaw.json` define o agente `prompt-engineer` com:
```json
{ "id": "prompt-engineer", "name": "Prompt Architect", "model": "ollama/llama3.3:3b" }
```
O modelo `llama3.3:3b` **não existe** no Ollama — a versão correta é `llama3.2:3b`. Esse agente falhará a cada chamada.

**Correção:**
```json
{ "id": "prompt-engineer", "name": "Prompt Architect", "model": "ollama/llama3.2:3b" }
```

---

## 🎯 MELHORIAS P1 — ALTO (Esta semana)

### P1-1: Hermes — Container Frágil (instalação em runtime)

**Diagnóstico:**
O container `hermes` no `docker-compose.yml` usa `ubuntu:24.04` e instala tudo via `apt-get` + `curl` **em runtime**:
```yaml
command: >
  bash -lc "
  apt-get update &&
  apt-get install -y curl bash ca-certificates &&
  curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash &&
  tail -f /dev/null
  "
```

**Problemas:**
1. Instala dependências a cada `docker-compose up` — lento (~2-5 min) e requer internet
2. O `install.sh` remoto pode mudar a qualquer momento (não é fixo/pinado)
3. `tail -f /dev/null` é um anti-pattern — sem processo principal, sem PID 1 correto
4. Container depende de `ollama: service_healthy` mas não tem healthcheck próprio

**Ação:**
- [ ] Criar um `Dockerfile.hermes` próprio com a instalação no build
- [ ] Ou avaliar se o Hermes é realmente necessário e remover se não estiver em uso

---

### P1-2: API Keys em Plaintext no `.env` versionado

**Diagnóstico crítico de segurança:**
O arquivo `.env` contém API keys reais em texto puro:
```env
GOOGLE_AI_KEY=AIzaSyD...
GROQ_API_KEY=gsk_UDgw...
OPENROUTER_API_KEY=sk-or-v1...
MOONSHOT_API_KEY=sk-0H9E...
NVAPI_API_KEY=nvapi-ch_...
TELEGRAM_BOT_TOKEN=8563126768:AAG...
OPENCLAW_GATEWAY_TOKEN=openclaw-dev-my-personal-assistant
OPENCLAW_GATEWAY_PASSWORD=red@1207
```

O `.gitignore` **exclui o `.env`** corretamente, mas o risco permanece em:
- Compartilhamento manual do repositório/pasta
- Backup automático do Windows incluindo o diretório
- Logs que possam espelhar variáveis de ambiente

**Ação imediata:**
- [ ] **Rotacionar todas as API keys** listadas acima (elas foram expostas em sessões de análise)
- [ ] Adicionar `.env.example` com valores placeholder para documentar o que é esperado
- [ ] Avaliar uso de **Docker Secrets** para credenciais críticas (Telegram token, Gateway password)

---

### P1-3: Consolidação dos Entrypoints Duplicados

**Situação atual (confusa):**
```
/
├── entrypoint.sh        ← executa gosu + openclaw gateway (arquivo operacional real)
├── entrypoint.js        ← referenciado no package.json como "main" — não usado pelo Docker
scripts/
├── entrypoint.sh        ← versão alternativa/de backup
├── entrypoint-backup.sh ← backup explícito do entrypoint
```

O `Dockerfile` define `ENTRYPOINT ["npx", "openclaw"]` mas o `entrypoint.sh` da raiz (copiado via `COPY . .`) faz o trabalho real via `gosu openclaw openclaw gateway`. Há conflito entre o que o Dockerfile declara e o que realmente executa.

**Ação:**
- [ ] Definir `entrypoint.sh` da raiz como **fonte da verdade**
- [ ] Remover `scripts/entrypoint.sh` e `scripts/entrypoint-backup.sh`
- [ ] Atualizar `Dockerfile`: `ENTRYPOINT ["/entrypoint.sh"]`
- [ ] Documentar a decisão no `CLAUDE.md`

---

### P1-4: Makefile Desatualizado e Inconsistente

**Diagnóstico:**
O `Makefile` atual foi escrito para uma versão antiga do projeto e está quebrado:
```makefile
run:
    docker run -it --rm \
        -v $(PWD)/data:/home/openclaw/.config/openclaw \  # ← Path errado (config não é .config)
        -e GEMINI_API_KEY=$$GEMINI_API_KEY \              # ← Gemini não está no .env atual
        -e GEMINI_MODEL=gemini-2.5-flash \                # ← Modelo não configurado
```
- Ignora o `docker-compose.yml` — gerencia o container de forma isolada
- O target `dashboard` usa `open` (macOS) sem fallback adequado para Windows
- Não tem target para `monitor`, `backup`, `logs-follow`, `shell`

**Ação:**
- [ ] Reescrever o `Makefile` para ser um alias conveniente do `deploy.sh` e scripts existentes
- [ ] Adicionar targets: `make up`, `make down`, `make logs`, `make monitor`, `make backup`, `make shell`
- [ ] Remover referências a `GEMINI_API_KEY` (não está no projeto)

---

### P1-5: `config/custom-config.yaml` Vazio

**Diagnóstico:**
O arquivo `config/custom-config.yaml` existe mas está **completamente vazio** (0 bytes além de newline). O `docker-compose.yml` **não monta** este arquivo no container. Indica funcionalidade planejada mas não implementada.

**Ação:**
- [ ] Documentar para que serve o `custom-config.yaml` (adicionar comentário/README no diretório)
- [ ] Ou remover o arquivo e o diretório `config/` se não houver plano de uso

---

### P1-6: IPs Fixos no `openclaw.json`

**Diagnóstico:**
O `openclaw.json` hardcoda IPs na seção `controlUi.allowedOrigins`:
```json
"http://172.18.0.1",
"http://172.18.0.1:18790",
"http://100.67.139.80",
"http://100.67.139.80:18790"
```
Se a subnet do Docker mudar ou o IP da máquina mudar, o WebUI pode parar de funcionar.

**Ação:**
- [ ] Substituir IPs fixos por wildcard `"*"` (já existe no final da lista) ou por variável de ambiente
- [ ] Documentar os IPs que são fixos por design (VPN, Tailscale)

---

## 🎯 MELHORIAS P2 — MÉDIO (Próxima sprint)

### P2-1: Observabilidade — Prometheus + Grafana

**Status:** Não existe ainda. É a melhoria com maior valor real a médio prazo.

O projeto já tem `scripts/monitor.sh` com `docker stats`, mas para histórico e alertas automáticos faz sentido um stack completo.

**Adicionar ao `docker-compose.yml`:**
```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: openclaw-prometheus
    ports:
      - "9090:9090"
    volumes:
      - prometheus_data:/prometheus
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    networks:
      - openclaw-net
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: openclaw-grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD:-changemeplease}
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - openclaw-net
    depends_on:
      - prometheus
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
```

**Adicionar ao `.env`:**
```env
GRAFANA_PASSWORD=troca-esta-senha
```

**Métricas prioritárias para o Ollama (NVIDIA):**
- Uso de VRAM (`nvidia-smi` via `nvidia_gpu_exporter`)
- Latência das chamadas de modelo
- Contagem de erros 4xx/5xx do gateway

> ⚠️ **Aviso de recursos:** Prometheus + Grafana consomem ~300MB de RAM adicionais. Verifique disponibilidade antes de ativar em ambiente com RTX 4060 8GB.

---

### P2-2: Documentação Desatualizada

**Diagnóstico:**
O `CLAUDE.md` (documentação principal) descreve uma arquitetura com **agentes que não existem**:
- Menciona "Atom (Roteador)", "OpenClaw (Códigos)", "Llama-70B (Chat)" como agentes — mas esses não estão em `openclaw.json`
- Lista agentes: "Observability Engineer", "Security Analyst", "Hardware IoT Engineer" — não configurados
- Paths de volume desatualizados: menciona `E:\\obsidian\\ai-data` mas o mount real é `E:/obsidian/OpenClaw`
- O `docs/STATUS-PRODUCAO.md` lista scripts como ativos (`monitor-api.sh`, `cleanup.sh`) que **não existem** no repositório

**Ação:**
- [ ] Atualizar `CLAUDE.md` para refletir os agentes reais: `main`, `tutor-english`, `tutor-iot`, `prompt-engineer`
- [ ] Atualizar paths do Obsidian Vault
- [ ] Sincronizar `docs/STATUS-PRODUCAO.md` com a realidade dos scripts (remover scripts fantasmas)
- [ ] Criar `docs/architecture/README.md` com diagrama atualizado

---

### P2-3: `docker-compose copy.yml` — Arquivo Duplicate na Raiz

**Diagnóstico:**
Existe um `docker-compose copy.yml` (com espaço no nome) na raiz do projeto, que é uma cópia antiga do `docker-compose.yml`. Arquivo com espaço no nome causa problemas em scripts bash.

**Ação:**
- [ ] Verificar se há diff relevante entre os dois arquivos
- [ ] Remover `docker-compose copy.yml` (o original tem precedência)

---

### P2-4: `data/config-schema.json` — Arquivo de 2MB

**Diagnóstico:**
O arquivo `data/config-schema.json` tem **2.1MB** — incomum para um schema. Pode ser um artefato gerado automaticamente pelo `openclaw doctor` que não deveria estar no controle versão (ou não deveria crescer indefinidamente).

**Ação:**
- [ ] Verificar se este arquivo é gerado automaticamente
- [ ] Se for gerado, adicionar ao `.gitignore`
- [ ] Se for necessário como seed, mantê-lo mas avaliar se 2MB é o tamanho esperado

---

### P2-5: Sistema de Memória — Convenções Obsidian

**Situação:** O plugin `memory-wiki` já gerencia memória via Obsidian Vault. Qualquer reestruturação deve seguir as convenções do Obsidian — não reinventar estrutura própria.

**Ação concreta (sem quebrar o que existe):**
- [ ] Criar `_index/` no vault com índices por categoria (`tutor-english/`, `tutor-iot/`, `main/`)
- [ ] Padronizar nomenclatura: `YYYY-MM-DD-tema.md` para logs diários
- [ ] Verificar que `autoCompile: true` está gerando o índice corretamente
- [ ] Criar um daily note template no Obsidian alinhado com o que o agente escreve

---

## 🎯 MELHORIAS P3 — BAIXO (Backlog)

### P3-1: CI/CD Básico com GitHub Actions

**O projeto tem `deploy.sh` completo** — falta apenas conectá-lo a um pipeline:
```yaml
# .github/workflows/validate.yml
on: [push]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate docker-compose
        run: docker-compose config --quiet
      - name: Lint shell scripts
        run: shellcheck entrypoint.sh scripts/*.sh
```

---

### P3-2: Adicionar `.env.example` ao Repositório

O `.env` real está no `.gitignore` (correto), mas não há `.env.example` para documentar quais variáveis são necessárias. Qualquer clone do projeto fica sem orientação.

**Ação:**
- [ ] Criar `.env.example` com variáveis sem valores reais
- [ ] Adicionar comentários explicativos em cada seção
- [ ] Referenciá-lo no `README.md`

---

### P3-3: Ollama — Listar e Versionar Modelos em Uso

**Diagnóstico:**
Os modelos usados (`qwen3.5:9b`, `llama3.1:8b`) não estão documentados nem há script de bootstrap para baixá-los automaticamente em um ambiente novo.

**Ação:**
- [ ] Criar `scripts/pull-models.sh` que faz pull dos modelos necessários
- [ ] Documentar no `README.md` quais modelos são necessários e como baixar
- [ ] Exemplo:
```bash
#!/bin/bash
# Pull de todos os modelos necessários para o ambiente
ollama pull qwen3.5:9b
ollama pull llama3.1:8b
ollama pull llama3.2:3b
```

---

### P3-4: Testes de Saúde Automatizados

**Diagnóstico:**
O arquivo `test_docker.sh` na raiz tem apenas 12 bytes (provavelmente um stub vazio).

**Ação:**
- [ ] Criar `scripts/health-check.sh` que verifica:
  - [ ] Todos os containers em estado `healthy`
  - [ ] Ollama responde em `GET /api/tags`
  - [ ] OpenClaw gateway responde em `GET /health`
  - [ ] Todos os modelos configurados estão disponíveis no Ollama

---

## 📋 PLANO DE LIMPEZA — Consolidação

> O que o plano original propunha como "melhoria" mas já está feito.
> Objetivo: documentar o que existe e propor limpeza de redundâncias.

---

### 🧹 L1: Dockerfile Multi-stage (Já feito)

**Estado atual:** O `Dockerfile` **já é multi-stage** com Node.js 20 Alpine.
- Stage `builder`: `npm install -g openclaw`
- Stage `runtime`: copia módulos, usuário não-root `openclaw` (UID 1001), healthcheck HTTP

**Limpeza proposta:**
- [ ] Corrigir comentário linha 68: `# Node.js v22 (LTS)` → na verdade é **v20**
- [ ] Verificar se `entrypoint.js` pode ser removido (o `entrypoint.sh` faz o trabalho real)

---

### 🧹 L2: Scripts de Operação (Já feito — mais completo)

**Estado atual:** Os scripts existentes são superiores:
```
deploy.sh        (464 linhas) — build, rollback, status, restore, predeploy
backup.sh        (raiz)       — backup básico com retenção 7 dias
scripts/
├── backup.sh                 — versão completa com envio para S3/remoto
├── monitor.sh                — loop de monitoramento com alertas Telegram
├── fix-all.sh                — reparação automática de problemas
├── fix-permissions.sh        — correção de permissões de volumes
├── repair-openclaw.sh        — reparação específica do container
└── quick-setup-multiagent.sh — setup inicial de agentes com knowledge base
```

**Limpeza proposta:**
- [ ] Unificar `backup.sh` da raiz e `scripts/backup.sh` — manter apenas `scripts/backup.sh`
- [ ] Mover `deploy.sh` da raiz para `scripts/deploy.sh`
- [ ] Atualizar `Makefile` para chamar os scripts de `scripts/`

---

### 🧹 L3: Segurança — Recursos e Usuário Não-root (Já feito)

**Estado atual:**
- `docker-compose.yml` define `deploy.resources` com limits e reservations para todos os serviços
- Usuário `openclaw` (UID 1001) não-root já no Dockerfile
- `entrypoint.sh` com verificação de permissões e `gosu`

**Limpeza proposta:**
- [ ] Remover `group_add: ["1000"]` do `docker-compose.yml` — possível conflito com UID 1001
- [ ] Documentar no `CLAUDE.md` por que `OPENCLAW_MEMORY_LIMIT` e `OPENCLAW_CPU_LIMIT` existem no `.env` mas não são usados no compose

---

### 🧹 L4: Arquivo `.env` (Já feito — mais organizado que o proposto originalmente)

**Estado atual:** O `.env` real tem seções bem organizadas com comentários.

**Limpeza proposta:**
- [ ] Corrigir comentário na linha 58: `# Portas de RedeOLLAMA_API_BASE` → `# Portas de Rede`
- [ ] Remover `# OPENCLAW_HOME=/home/openclaw/.config/openclaw` (comentário confuso)
- [ ] Adicionar `GRAFANA_PASSWORD` para quando P2-1 for implementado
- [ ] Criar `.env.example` parallel (veja P3-2)

---

## 📊 Priorização Final

### P0 — Crítico (Hoje)
- [x] **P0-1** Corrigir modelo primário no `openclaw.json` (erro 403 ativo)
- [x] **P0-2** Usar `${OBSIDIAN_VAULT_HOST}` no `docker-compose.yml`
- [ ] **P0-3** Criar config nginx ou desativar container nginx vazio
- [x] **P0-4** Corrigir modelo do agente `prompt-engineer` (`llama3.3:3b` → `llama3.2:3b`)

### P1 — Alto (Esta semana)
- [ ] **P1-1** Criar Dockerfile próprio para Hermes ou avaliar remoção
- [ ] **P1-2** Rotacionar API keys expostas e adicionar `.env.example`
- [ ] **P1-3** Consolidar entrypoints duplicados
- [ ] **P1-4** Reescrever Makefile desatualizado
- [ ] **P1-5** Documentar ou remover `config/custom-config.yaml`
- [ ] **P1-6** Remover IPs fixos do `openclaw.json`

### P2 — Médio (Próxima sprint)
- [ ] **P2-1** Implementar Prometheus + Grafana (verificar RAM disponível)
- [ ] **P2-2** Atualizar documentação desatualizada (CLAUDE.md, STATUS-PRODUCAO.md)
- [ ] **P2-3** Remover `docker-compose copy.yml`
- [ ] **P2-4** Verificar e remover `data/config-schema.json` do versionamento
- [ ] **P2-5** Estrutura de memória Obsidian com templates

### P3 — Baixo (Backlog)
- [ ] **P3-1** CI/CD com GitHub Actions (shellcheck, docker-compose validate)
- [ ] **P3-2** Criar `.env.example`
- [ ] **P3-3** Script `pull-models.sh` para bootstrap do Ollama
- [ ] **P3-4** Testes de saúde automatizados (`health-check.sh`)

---

## 📈 Métricas de Sucesso Reais

### Estabilidade
- [ ] Zero erros 403 nos logs do gateway
- [ ] `docker-compose ps` mostrando todos os containers `healthy`
- [ ] Ollama respondendo modelos locais em < 30s no primeiro start

### Portabilidade
- [ ] Projeto sobe com `docker-compose up -d` em outra máquina após ajustar apenas o `.env`
- [ ] Nenhum path absoluto hardcoded no `docker-compose.yml`

### Segurança
- [ ] API keys rotacionadas e não mais expostas
- [ ] `.env.example` publicado, `.env` real apenas local
- [ ] Nginx com proxy ativo (não vazio)

### Observabilidade (após P2-1)
- [ ] Dashboard Grafana com VRAM e latência
- [ ] Alertas configurados para uso > 90% de VRAM

---

## 🚀 Próximos Passos Imediatos

```bash
# 1. Corrigir openclaw.json (P0-1 e P0-4)
# Editar agents.defaults.model.primary → ollama/qwen3.5:9b
# Editar agente prompt-engineer → llama3.2:3b (não llama3.3:3b)

# 2. Corrigir docker-compose.yml (P0-2)
# Linha 73: E:/obsidian/OpenClaw → ${OBSIDIAN_VAULT_HOST}

# 3. Criar nginx/conf.d/openclaw.conf (P0-3)
# Ou desativar o serviço nginx no compose

# 4. Reiniciar containers afetados
docker-compose restart openclaw

# 5. Verificar saúde
docker-compose ps
docker-compose logs openclaw --tail=50
```
