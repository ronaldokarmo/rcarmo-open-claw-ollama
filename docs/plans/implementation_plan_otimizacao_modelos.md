# Plano de Curadoria e Otimização de Modelos

## Diagnóstico: O que você tem hoje

### 📦 Modelos Instalados Localmente (Ollama)

| Modelo | Tamanho | Quando baixou |
|---|---|---|
| `qwen3.5:9b` | **6.6 GB** | 10 dias atrás |
| `qwen3.5:latest` | **6.6 GB (mesmo!)** | 5 semanas atrás |
| `llama3.1:8b` | **4.9 GB** | 6 semanas atrás |
| `kimi-k2.5:cloud` | **- (sem peso)** | 3 semanas atrás |

> [!IMPORTANT]
> `qwen3.5` e `qwen3.5:9b` são **exatamente o mesmo modelo** (ID `6488c96fa5fa`). Você está ocupando **6.6 GB em disco à toa**. O `:latest` pode ser removido com segurança.

### ☁️ Provedores de Nuvem Configurados

| Provedor | Modelos | API Key |
|---|---|---|
| **Groq** | Llama 70B, Llama 8B Instant, Gemma 2 9B, Mixtral 8x7B | `${GROQ_API_KEY}` |
| **NVIDIA NIM** | Kimi K2.5 (6 variantes: cloud, preview, turbo, thinking...) | `${MOONSHOT_API_KEY}` |
| **Qwen Portal** | Coder Model, Vision Model | OAuth (qwen-portal) |
| **Ollama** | Qwen 3.5, Llama 3.1, Kimi (cloud tag) | Local |

---

## 🧠 O "Manual do Proprietário" dos seus Modelos

Aqui está o que você precisa saber para nunca mais ter dúvida sobre qual usar:

### Groq (Nuvem Gratuita/Barata, Extremamente Rápida)
A Groq usa chips chamados **LPU** que são 10x mais rápidos que GPU para inferência. Ideal para respostas curtas e rápidas.

| Modelo | Melhor Para | Evitar Quando |
|---|---|---|
| `llama-3.3-70b-versatile` | ✅ Raciocínio complexo, redação, análise | Muitas mensagens curtas seguidas (cota) |
| `llama-3.1-8b-instant` | ✅ Respostas ultra-rápidas, triagem, heartbeat | Tarefas que exigem profundidade |
| `gemma2-9b-it` | ✅ Conversas instruídas, seguir regras | Código complexo |
| `mixtral-8x7b-32768` | ✅ Contexto longo (32k), múltiplos idiomas | Prompts de alta precisão |

### NVIDIA NIM (Kimi K2.5 — As 6 Variantes)
O **Kimi K2.5** é o modelo da Moonshot AI. Você tem 6 variantes configuradas, mas a confusão é comum:

| Variante | O que é | Use Quando |
|---|---|---|
| `kimi-k2.5` (cloud) | Versão padrão mais recente | **Roteador principal** (uso diário) |
| `kimi-k2-0905-preview` | Versão de pesquisa de setembro | Evitar — snapshot antigo |
| `kimi-k2-turbo-preview` | Versão mais rápida, menos detalhada | Respostas rápidas com Kimi |
| `kimi-k2-thinking` | Modo raciocínio profundo (chain-of-thought) | ✅ Problemas difíceis, planejamento |
| `kimi-k2-thinking-turbo` | Raciocínio rápido | Equilíbrio velocidade/profundidade |
| `moonshotai/kimi-k2.5` (NIM) | Mesmo Kimi no endpoint NIM | Redundante com o `:cloud` do Ollama |

> [!WARNING]
> Você tem **2 caminhos para o mesmo Kimi K2.5**: via `ollama/kimi-k2.5:cloud` e via `nvidia-nim/moonshotai/kimi-k2.5`. Ambos apontam para a nuvem do Moonshot AI. O via Ollama é mais direto.

### Qwen Portal (OAuth — Gratuito da Alibaba)
| Modelo | Melhor Para |
|---|---|
| `qwen-portal/coder-model` | ✅ Código (Python, JS, C++) |
| `qwen-portal/vision-model` | ✅ Análise de imagens, screenshots |

### Ollama Local (GPU — Sua RTX 4060 8GB)
| Modelo | Melhor Para | VRAM |
|---|---|---|
| `qwen3.5:9b` | ✅ Código, lógica, roteamento offline | ~6 GB |
| `llama3.1:8b` | ✅ Conversas em inglês, textos | ~5 GB |
| `kimi-k2.5:cloud` | Tag sem peso — apenas proxy para nuvem | ~0 GB |

---

## 🎯 Plano de Ação em 3 Fases

### Fase 1: Limpeza (Imediato — 5 min)

**Remover o modelo duplicado:**
```bash
docker exec ollama ollama rm qwen3.5:latest
```
Isso libera **6.6 GB em disco** e elimina a ambiguidade entre `qwen3.5` e `qwen3.5:9b`.

**Remover a entrada duplicada do `openclaw.json`:**
O modelo `ollama/qwen3.5` (sem tag) aponta para o mesmo alias que `qwen3.5:9b`. Vamos remover a referência desnecessária.

---

### Fase 2: Consolidação (Configuração — 15 min)

**Reorganizar o `openclaw.json` para refletir nossa estratégia:**

#### Modelos Ollama: Manter apenas 2 referências limpas
```json
"ollama": {
  "models": [
    { "id": "qwen3.5:9b",   "name": "Qwen 3.5 9B",   "contextWindow": 32768, "maxTokens": 4096 },
    { "id": "llama3.1:8b",  "name": "Llama 3.1 8B",  "contextWindow": 65536, "maxTokens": 4096 },
    { "id": "kimi-k2.5:cloud", "name": "Kimi K2.5 (Cloud)", "contextWindow": 128000, "maxTokens": 8192 }
  ]
}
```
*(Remover: `qwen3.5` sem tag)*

#### NVIDIA NIM: Manter apenas o que faz sentido
```json
"nvidia-nim": {
  "models": [
    { "id": "kimi-k2.5",          "name": "Kimi K2.5"                },
    { "id": "kimi-k2-thinking",    "name": "Kimi K2 Thinking"         },
    { "id": "kimi-k2-thinking-turbo", "name": "Kimi K2 Thinking Turbo" }
  ]
}
```
*(Remover: `moonshotai/kimi-k2.5` (duplic.), `kimi-k2-0905-preview` (snapshot antigo), `kimi-k2-turbo-preview`)*

#### `agents.defaults.model.fallbacks`: Cadeia de fallback limpa
```json
"model": {
  "primary": "ollama/kimi-k2.5:cloud",
  "fallbacks": [
    "groq/llama-3.3-70b-versatile",
    "ollama/qwen3.5:9b",
    "ollama/llama3.1:8b"
  ]
}
```

---

### Fase 3: Alocação Definitiva por Agente + Caso de Uso

**A tabela mestra do seu ecossistema:**

| Agente / Uso | Modelo Primário | Fallback | Razão |
|---|---|---|---|
| **Main (Roteador)** | `ollama/kimi-k2.5:cloud` | `groq/llama-3.3-70b` | Kimi é excelente em roteamento multilíngue |
| **Tutor English** | `groq/llama-3.1-8b-instant` | `ollama/llama3.1:8b` | Llama nativo em inglês, Groq é ultra-rápido |
| **Tutor IoT** | `ollama/qwen3.5:9b` | `qwen-portal/coder-model` | Qwen local é líder em código |
| **Prompt Architect** | `groq/llama-3.3-70b-versatile` | `nvidia-nim/kimi-k2-thinking` | Máxima cognição para otimização |
| **Tarefas longas / Planejamento** | `nvidia-nim/kimi-k2-thinking` | `groq/llama-3.3-70b` | Chain-of-thought para problemas difíceis |
| **Análise de imagens** | `qwen-portal/vision-model` | - | Único com capacidade multimodal |
| **Heartbeat / Resumos** | `groq/llama-3.1-8b-instant` | `ollama/llama3.1:8b` | Leve, rápido, barato |

---

## Verificação Final

```bash
# Confirmar limpeza pós-remoção
docker exec ollama ollama list

# Verificar saúde da configuração
docker exec openclaw bash -c "openclaw doctor 2>/dev/null"

# Confirmar que agentes estão com modelos corretos
docker exec openclaw bash -c "openclaw agents list 2>/dev/null"
```

## Resumo do que será removido/simplificado

| Item | Ação | Ganho |
|---|---|---|
| `qwen3.5:latest` (local) | 🗑️ Remover via Ollama | +6.6 GB disco |
| `ollama/qwen3.5` (sem tag, no json) | 🗑️ Remover do config | Menos ambiguidade |
| `nvidia-nim/moonshotai/kimi-k2.5` | 🗑️ Remover (duplica Kimi) | Configuração limpa |
| `nvidia-nim/kimi-k2-0905-preview` | 🗑️ Remover (snapshot antigo) | Sem ruído |
| `nvidia-nim/kimi-k2-turbo-preview` | 🗑️ Remover (substituído pelo Thinking Turbo) | Sem ruído |
| **Total simplificado** | De 16 entradas de modelo → **11 entradas** | Ecossistema organizado |
