# Integração Obsidian Vault ↔ OpenClaw (Fase 1 + Fase 2)

## Contexto

Montar o Obsidian Vault (`E:\obsidian\ai-data`) dentro do container OpenClaw e integrá-lo com os mecanismos nativos do OpenClaw para que o agente possa pesquisar, indexar e consumir o conteúdo do vault como base de conhecimento.

**Descoberta principal da pesquisa:** O OpenClaw possui um **plugin nativo `memory-wiki`** descrito como *"Persistent wiki compiler and Obsidian-friendly knowledge vault"* — está **bundled mas desabilitado por padrão**. Ele suporta configuração de vault Obsidian com campos como `vault.path`, `vault.renderMode: obsidian`, `obsidian.enabled`, `obsidian.vaultName`, e subsistemas de `bridge`, `search`, e `ingest`.

### Estado atual do Vault

| Pasta | Conteúdo |
|---|---|
| `Knowledge/` | 2 notas: `OpenClaw.md.md`, `Obsidian.md.md` |
| `Memory/` | 3 notas: `Comandos Úteis.md.md`, `Preferências.md.md`, `Setup.md.md` |
| `Projects/` | 1 nota: `OpenClaw+Obsidian.md.md` |
| `.obsidian/` | Configuração do app Obsidian |
| **Total** | **6 arquivos .md** |

---

## Fase 1 — Infraestrutura (mount do volume)

### [MODIFY] [docker-compose.yml](file:///e:/openclaw-docker/docker-compose.yml)

**1. Adicionar volume do Obsidian Vault (linha ~41):**

```diff
     volumes:
       - ./data/.openclaw:/home/openclaw/.openclaw
       - ./logs:/home/openclaw/logs
       - /var/run/docker.sock:/var/run/docker.sock:ro
+      # Obsidian Vault (leitura/escrita para o plugin memory-wiki)
+      - E:/obsidian/ai-data:/home/openclaw/obsidian:rw
```

> [!NOTE]
> Uso `rw` (leitura/escrita) em vez de `ro` porque o plugin `memory-wiki` precisa escrever metadados compilados e índices dentro do vault.

**2. Adicionar variáveis de ambiente (após linha 37):**

```diff
       - NODE_OPTIONS=--dns-result-order=ipv4first
+      - OBSIDIAN_VAULT_PATH=/home/openclaw/obsidian
+      - VAULT_ROOT=/home/openclaw/obsidian/Knowledge
```

---

### [MODIFY] [.env](file:///e:/openclaw-docker/.env)

Adicionar seção de referência:

```diff
 DATA_VOLUME=./data
 LOGS_VOLUME=./logs
+
+# ==================== OBSIDIAN VAULT ====================
+# Caminho do Obsidian Vault no host Windows
+OBSIDIAN_VAULT_HOST=E:/obsidian/ai-data
+# Caminho interno no container
+OBSIDIAN_VAULT_PATH=/home/openclaw/obsidian
+VAULT_ROOT=/home/openclaw/obsidian/Knowledge
```

---

## Fase 2 — Integração com OpenClaw

### 2A. Habilitar plugin `memory-wiki` com configuração Obsidian

### [MODIFY] [openclaw.json](file:///e:/openclaw-docker/data/.openclaw/openclaw.json)

Adicionar configuração do plugin `memory-wiki` dentro da seção `plugins.entries`:

```diff
   "plugins": {
     "entries": {
       "ollama": {
         "enabled": true
       },
       "moonshot": {
         "enabled": true
-      }
+      },
+      "memory-wiki": {
+        "enabled": true,
+        "config": {
+          "vaultMode": "bridge",
+          "vault": {
+            "path": "/home/openclaw/obsidian",
+            "renderMode": "obsidian"
+          },
+          "obsidian": {
+            "enabled": true,
+            "vaultName": "ai-data",
+            "openAfterWrites": false
+          },
+          "bridge": {
+            "enabled": true,
+            "readMemoryArtifacts": true,
+            "indexMemoryRoot": true,
+            "followMemoryEvents": true
+          },
+          "search": {
+            "backend": "local",
+            "corpus": "all"
+          },
+          "ingest": {
+            "autoCompile": true,
+            "maxConcurrentJobs": 1
+          }
+        }
+      }
     }
   }
```

**Explicação dos campos (baseado no schema extraído):**

| Campo | Valor | Razão |
|---|---|---|
| `vaultMode` | `"bridge"` | Modo intermediário: lê/escreve no vault externo mas mantém isolamento |
| `vault.path` | `"/home/openclaw/obsidian"` | Caminho interno do volume montado |
| `vault.renderMode` | `"obsidian"` | Renderiza Markdown no formato Obsidian (wikilinks, etc.) |
| `obsidian.enabled` | `true` | Ativa integração Obsidian |
| `obsidian.vaultName` | `"ai-data"` | Nome do vault (match com a pasta real) |
| `obsidian.openAfterWrites` | `false` | Não abrir Obsidian automaticamente (Docker headless) |
| `bridge.readMemoryArtifacts` | `true` | Ler artefatos de memória do vault |
| `bridge.indexMemoryRoot` | `true` | Indexar a raiz da memória |
| `bridge.followMemoryEvents` | `true` | Reagir a eventos de memória |
| `search.backend` | `"local"` | Busca local (sem dependência externa) |
| `search.corpus` | `"all"` | Buscar em wiki + memory |
| `ingest.autoCompile` | `true` | Compilar automaticamente novas notas |
| `ingest.maxConcurrentJobs` | `1` | Limitar jobs (conservar RAM) |

---

### 2B. Habilitar memory search nos agentes

### [MODIFY] [openclaw.json](file:///e:/openclaw-docker/data/.openclaw/openclaw.json)

Ativar o `memorySearch` que está atualmente desabilitado:

```diff
       "memorySearch": {
-        "enabled": false
+        "enabled": true
       },
```

---

### 2C. Criar skill `obsidian-vault-search`

### [NEW] [SKILL.md](file:///e:/openclaw-docker/data/.openclaw/skills/obsidian-vault-search/SKILL.md)

```markdown
---
name: obsidian-vault-search
description: Busca e consulta notas no Obsidian Vault montado em /home/openclaw/obsidian. Use quando o usuário perguntar sobre informações armazenadas no vault, quiser buscar notas, consultar Knowledge, Memory ou Projects. Triggers: "buscar no vault", "consultar notas", "obsidian", "knowledge base", "o que eu tenho sobre", "notas sobre".
---

# Obsidian Vault Search

## Purpose

Search and retrieve information from the Obsidian vault mounted at `$OBSIDIAN_VAULT_PATH` (/home/openclaw/obsidian).

## Vault Structure

- **Knowledge/** — Base de conhecimento permanente (conceitos, referências)
- **Memory/** — Memória operacional (comandos úteis, preferências, setup)
- **Projects/** — Notas de projetos ativos

## When to Use

- User asks about stored knowledge or notes
- User wants to find information in their vault
- User references "vault", "obsidian", "notas", or "knowledge"
- User asks "o que eu tenho sobre X?"

## Steps

1. Identify the search intent and keywords from the user's message

2. Search across all vault directories:
   ```bash
   grep -ril "<keywords>" /home/openclaw/obsidian/ --include="*.md" 2>/dev/null
   ```

3. If results found, read the relevant files:
   ```bash
   cat "/home/openclaw/obsidian/<path>/<file>.md"
   ```

4. If no grep results, list available notes for context:
   ```bash
   find /home/openclaw/obsidian -name "*.md" -not -path "*/.obsidian/*" | sort
   ```

5. Summarize findings clearly, referencing the source file

## Output Requirements

- Always mention which file(s) the information came from
- If no results found, list available topics
- Suggest creating a new note if the topic doesn't exist
- Use Portuguese (pt-BR) for responses

## Configuration

- **vault_path**: $OBSIDIAN_VAULT_PATH (default: /home/openclaw/obsidian)
- **read_only**: false (can suggest creating new notes)
- **response_language**: pt-BR
```

---

## Sequência de Execução

```text
═══════════════════ FASE 1 ═══════════════════

1. Editar docker-compose.yml
   → Adicionar volume + env vars

2. Editar .env
   → Adicionar variáveis de referência

═══════════════════ FASE 2 ═══════════════════

3. Editar openclaw.json
   → Ativar plugin memory-wiki com config Obsidian
   → Ativar memorySearch

4. Criar skill obsidian-vault-search
   → data/.openclaw/skills/obsidian-vault-search/SKILL.md

═══════════════════ DEPLOY ═══════════════════

5. docker compose stop openclaw

6. docker compose up -d openclaw
   (não precisa --build, só config + volumes mudaram)

═══════════════════ VERIFICAR ═══════════════════

7. Rodar testes de verificação (ver seção abaixo)
```

---

## Plano de Verificação

### Teste 1 — Volume montado
```bash
docker exec openclaw ls -la /home/openclaw/obsidian/
# Espera: Knowledge/ Memory/ Projects/ .obsidian/
```

### Teste 2 — Variáveis de ambiente
```bash
docker exec openclaw printenv | grep -E "OBSIDIAN|VAULT"
# Espera: OBSIDIAN_VAULT_PATH=/home/openclaw/obsidian
#         VAULT_ROOT=/home/openclaw/obsidian/Knowledge
```

### Teste 3 — Plugin memory-wiki ativo
```bash
docker exec openclaw bash -c "openclaw plugins list 2>/dev/null" | grep memory-wiki
# Espera: status = "loaded" (não "disabled")
```

### Teste 4 — Leitura do vault
```bash
docker exec openclaw cat /home/openclaw/obsidian/Knowledge/OpenClaw.md.md
# Espera: conteúdo da nota sobre OpenClaw
```

### Teste 5 — Skill carregada
```bash
docker exec openclaw bash -c "openclaw skills list 2>/dev/null" | grep obsidian
# Espera: obsidian-vault-search listada como "ready"
```

### Teste 6 — Container saudável
```bash
docker ps --filter name=openclaw --format "{{.Status}}"
# Espera: "Up X (healthy)"
```

### Teste 7 — Memory search funcional
```bash
docker exec openclaw bash -c "openclaw memory status 2>/dev/null"
# Espera: NOT "Memory search disabled"
```

---

## Riscos e Mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| Plugin memory-wiki incompatível com v2026.4.11 | Médio | É bundled stock; se falhar, desabilitar e manter só a skill |
| Extensão `.md.md` nas notas | Baixo | O grep e cat funcionam normalmente; cosmético apenas |
| Escrita no vault NTFS via WSL2 | Médio | Plugin pode gerar warnings POSIX; `openAfterWrites: false` evita calls ao Obsidian |
| Aumento de uso de RAM/CPU | Baixo | `maxConcurrentJobs: 1` e `maxConcurrent: 1` limitam recursos |
| Container não reinicia (config inválida) | Alto | Backup do `openclaw.json` já existe (`.bak`); rollback rápido |

> [!WARNING]
> **Versão desatualizada:** O OpenClaw v2026.4.11 está rodando com config escrita por v2026.4.15. Se o plugin `memory-wiki` depender de features do 2026.4.15, pode não funcionar. Nesse caso, faremos rollback do plugin e manteremos apenas a skill + volume.

---

## Resumo das alterações

| Arquivo | Ação | Fase |
|---|---|---|
| `docker-compose.yml` | Adicionar volume + 2 env vars | 1 |
| `.env` | Adicionar 3 variáveis de referência | 1 |
| `openclaw.json` | Ativar memory-wiki + memorySearch | 2 |
| `skills/obsidian-vault-search/SKILL.md` | Criar nova skill | 2 |

**Total: 3 arquivos modificados + 1 arquivo novo**
