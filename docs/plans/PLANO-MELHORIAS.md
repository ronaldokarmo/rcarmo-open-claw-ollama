# Plano de Melhorias do OpenClaw Docker

> **Revisão Crítica:** `2026-04-25`
> Plano auditado contra o estado real do projeto. Itens já implementados foram movidos para o [Plano de Limpeza](#-plano-de-limpeza--consolidação). Itens incorretos foram removidos.

---

## 📋 Contexto

O projeto OpenClaw é uma plataforma de rede de agentes LLM baseada em **Node.js** (não Python), rodando via `openclaw gateway` num container Alpine. O ambiente atual conta com:

- `openclaw` container (Node.js 20 Alpine, multi-stage)
- `ollama` container (GPU NVIDIA RTX 4060, 8GB VRAM)
- `nginx` container (proxy reverso)
- `hermes` container (agente auxiliar)
- Plugin `memory-wiki` integrado com Obsidian Vault
- Agentes ativos: `main`, `tutor-english`, `tutor-iot`, `prompt-engineer`

---

## 🚨 MELHORIAS P0 — CRÍTICO (Problemas Ativos)

### Problema 1: Modelos Cloud causando erro 403

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

### Problema 2: Path do Obsidian hardcoded no docker-compose

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

**Impacto:** Portabilidade total. Qualquer pessoa clona e ajusta apenas o `.env`.

---

## 🎯 MELHORIAS P1 — ALTO (Fazer esta semana)

### Melhoria 1: Consolidação dos Entrypoints

**Situação atual (confusa):**
```
/
├── entrypoint.sh        ← executa gosu + openclaw gateway (arquivo operacional)
├── entrypoint.js        ← referenciado no Dockerfile? Confuso
scripts/
├── entrypoint.sh        ← cópia/versão alternativa
├── entrypoint-backup.sh ← backup do entrypoint
```

O `Dockerfile` define `ENTRYPOINT ["npx", "openclaw"]` mas o `entrypoint.sh` da raiz faz o trabalho real via `gosu openclaw openclaw gateway`. Há conflito.

**Ação:**
- [ ] Definir `entrypoint.sh` da raiz como **fonte da verdade**
- [ ] Remover `scripts/entrypoint.sh` e `scripts/entrypoint-backup.sh`
- [ ] Atualizar `Dockerfile`: `ENTRYPOINT ["/entrypoint.sh"]` (se aplicável)
- [ ] Documentar a decisão no `CLAUDE.md`

---

### Melhoria 2: Segmentação de Rede — IPs Fixos

**Diagnóstico:**
O `openclaw.json` hardcoda IPs na seção `controlUi.allowedOrigins`:
```json
"http://172.18.0.1",
"http://172.18.0.1:18790",
"http://100.67.139.80",
```
O `.env` comentado também contém:
```env
# OLLAMA_API_BASE=http://172.18.0.3:11434
```
Se a subnet do Docker mudar, o sistema pode parar de funcionar.

**Ação:**
- [ ] Substituir IPs fixos por referências DNS (`ollama`, `openclaw`) onde possível
- [ ] Manter IPs apenas como fallback documentado, não como primário

---

## 🎯 MELHORIAS P2 — MÉDIO (Próxima sprint)

### Melhoria 3: Observabilidade — Prometheus + Grafana

**Status:** ✅ Não existe ainda. É a única melhoria completamente nova do plano original.

O projeto já tem `scripts/monitor.sh` com `docker stats`, mas para observabilidade persistente e histórica faz sentido um stack completo.

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
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD:-admin}
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
PROMETHEUS_PORT=9090
GRAFANA_PORT=3001
GRAFANA_PASSWORD=troca-esta-senha
```

**Métricas prioritárias:**
- Uso de VRAM do Ollama (via `nvidia_smi_exporter`)
- Latência das chamadas de modelo
- Contagem de erros 4xx/5xx do gateway

> ⚠️ **Para uso pessoal com RTX 4060 8GB:** Prometheus + Grafana consomem ~300MB de RAM adicionais. Avalie se o hardware comporta antes de ativar.

---

### Melhoria 4: Estrutura de Memória do Agente

**Situação:** O plugin `memory-wiki` já gerencia memória via Obsidian Vault. Qualquer reestruturação deve seguir as convenções do Obsidian, não reinventar.

**Ação concreta (sem quebrar o que existe):**
- [ ] Criar pasta `Knowledge/_index/` no vault para índices por categoria
- [ ] Padronizar nomenclatura: `YYYY-MM-DD-tema.md` em vez de `YYYY-MM-DD.md`
- [ ] Configurar `autoCompile: true` (já está) e verificar que o índice está sendo gerado

---

## 📋 PLANO DE LIMPEZA — Consolidação

> **O que o plano original propunha como "melhoria" mas já está feito.**
> Objetivo: documentar o que existe e propor limpeza de redundâncias.

---

### 🧹 Item L1: Dockerfile Multi-stage (Já feito)

**Estado atual:** O `Dockerfile` **já é multi-stage** com Node.js 20 Alpine:
- Stage `builder`: `npm install -g openclaw`
- Stage `runtime`: copia módulos, cria usuário `openclaw` (UID 1001), healthcheck HTTP, roda na porta `18790`

**Limpeza proposta:**
- [ ] Remover comentário desatualizado na linha 68: `# Node.js v22 (LTS)` → na verdade é v20
- [ ] Verificar se `entrypoint.js` ainda é necessário ou pode ser removido (o `entrypoint.sh` faz o trabalho real)
- [ ] Consolidar o `COPY . .` que aparece duas vezes no plano original (bug)

---

### 🧹 Item L2: Scripts de Operação (Já feito — mais completo)

**Estado atual:** Os scripts existentes são **superiores** ao proposto no plano:
```
deploy.sh       (12KB) — com rollback, logs coloridos, healthcheck loop
backup.sh               — na raiz com retenção de 7 dias
scripts/
├── backup.sh           — versão avançada em scripts/
├── monitor.sh          — monitoramento via docker stats
├── fix-all.sh          — reparação automática de problemas comuns
├── fix-permissions.sh  — correção de permissões de volumes
└── repair-openclaw.sh  — reparação do container openclaw
```

**Limpeza proposta:**
- [ ] Auditar se `backup.sh` da raiz e `scripts/backup.sh` fazem a mesma coisa → consolidar em um só
- [ ] Mover `deploy.sh` da raiz para `scripts/deploy.sh` para organização
- [ ] Adicionar `scripts/` ao `Makefile` como alvos: `make backup`, `make deploy`, `make monitor`

---

### 🧹 Item L3: Segurança — Grupos e Permissões (Já feito)

**Estado atual:** Já implementado no `docker-compose.yml`:
```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 2G
    reservations:
      cpus: '2'
      memory: 1G
```
Usuário não-root `openclaw` (UID 1001) já no Dockerfile.

**Limpeza proposta:**
- [ ] Remover `group_add: ["1000"]` do `docker-compose.yml` se não for necessário (potencial conflito com UID 1001 do container)
- [ ] Documentar no `CLAUDE.md` por que `OPENCLAW_MEMORY_LIMIT` e `OPENCLAW_CPU_LIMIT` no `.env` existem mas não são usados no compose (vars definidas mas não referenciadas)

---

### 🧹 Item L4: Arquivo .env (Já feito — mais organizado que o proposto)

**Estado atual:** O `.env` real já tem organização por seções com comentários explicativos.

**Limpeza proposta:**
- [ ] Remover `# OPENCLAW_HOME=/home/openclaw/.config/openclaw` (comentário confuso)
- [ ] Corrigir comentário na linha 58: `# Portas de RedeOLLAMA_API_BASE` → `# Portas de Rede`
- [ ] Adicionar `GRAFANA_PASSWORD` para quando o P2 for implementado
- [ ] **⚠️ ATENÇÃO:** O `.env` contém API keys em plaintext visíveis no repositório (Google AI, Groq, OpenRouter, Moonshot, NVAPI, Telegram). Se este repo for público ou compartilhado, **rotacionar todas as chaves imediatamente**.

---

## 📊 Priorização Final

### P0 — Crítico (Fazer hoje)
- [ ] Corrigir modelo primário no `openclaw.json` (erro 403 ativo)
- [ ] Usar `${OBSIDIAN_VAULT_HOST}` no `docker-compose.yml`

### P1 — Alto (Esta semana)
- [ ] Consolidar entrypoints duplicados
- [ ] Remover IPs hardcoded do `openclaw.json`
- [ ] Limpeza L3: remover `group_add` desnecessário

### P2 — Médio (Próxima sprint)
- [ ] Implementar Prometheus + Grafana (verificar RAM disponível antes)
- [ ] Consolidar scripts duplicados (`backup.sh`)
- [ ] Estrutura de memória no Obsidian

### P3 — Baixo (Backlog)
- [ ] Documentação técnica completa em `docs/architecture/`
- [ ] Testes de carga e benchmark de modelos
- [ ] Limpeza de comentários obsoletos no Dockerfile e `.env`

---

## 📈 Métricas de Sucesso Reais

### Estabilidade
- [ ] Zero erros 403 nos logs do gateway
- [ ] `docker-compose ps` mostrando todos os containers `healthy`
- [ ] Ollama respondendo modelos locais em < 30s

### Portabilidade
- [ ] Projeto sobe com `docker-compose up -d` em outra máquina após ajustar apenas o `.env`
- [ ] Nenhum path absoluto no `docker-compose.yml`

### Observabilidade (após P2)
- [ ] Dashboard Grafana com VRAM e latência
- [ ] Alertas configurados para uso > 90% de VRAM

---

## 🚀 Próximos Passos Imediatos

```bash
# 1. Corrigir openclaw.json (P0)
# Editar agents.defaults.model.primary para ollama/qwen3.5:9b

# 2. Corrigir docker-compose.yml (P0)
# Linha 73: substituir E:/obsidian/OpenClaw por ${OBSIDIAN_VAULT_HOST}

# 3. Reiniciar o container
docker-compose restart openclaw

# 4. Verificar saúde
docker-compose ps
docker-compose logs openclaw --tail=50
```
