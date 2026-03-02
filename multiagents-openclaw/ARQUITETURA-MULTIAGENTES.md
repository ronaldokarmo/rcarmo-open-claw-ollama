# 🏗️ Arquitetura de Multiagentes OpenClaw

## 📊 Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                         TELEGRAM BOT                             │
│                      (Interface do Usuário)                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ├─ Usuário: "Preciso de ajuda com inglês"
                             ├─ Usuário: "Como conectar sensor DHT22?"
                             ├─ Usuário: "@tutor-iot: ESP32 pinout?"
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      OPENCLAW GATEWAY                            │
│                        (Port 18790)                              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │             WebSocket + HTTP Server                       │  │
│  │  • Autenticação                                           │  │
│  │  • Rate limiting                                          │  │
│  │  • Logging                                                │  │
│  └───────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ROUTING ENGINE                                │
│                  (Análise e Decisão)                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  1. Análise de Keywords                                   │  │
│  │     ├─ "english", "grammar" → tutor-english              │  │
│  │     ├─ "arduino", "sensor" → tutor-iot                   │  │
│  │     └─ Outros → main                                      │  │
│  │                                                            │  │
│  │  2. Pattern Matching                                      │  │
│  │     ├─ @agent-id: [msg] → Delegação direta              │  │
│  │     └─ Regex patterns → Análise contextual               │  │
│  │                                                            │  │
│  │  3. Confidence Scoring                                    │  │
│  │     └─ Threshold: 0.7                                     │  │
│  └───────────────────────────────────────────────────────────┘  │
└────────┬───────────────────┬────────────────────┬───────────────┘
         │                   │                    │
         ▼                   ▼                    ▼
┌────────────────┐  ┌─────────────────┐  ┌──────────────────┐
│  MAIN AGENT    │  │ TUTOR-ENGLISH   │  │   TUTOR-IOT      │
│ (Coordinator)  │  │  (Specialist)   │  │  (Specialist)    │
├────────────────┤  ├─────────────────┤  ├──────────────────┤
│ • Routing      │  │ • Grammar       │  │ • Arduino        │
│ • Context      │  │ • Vocabulary    │  │ • ESP32          │
│ • Delegation   │  │ • Translation   │  │ • Sensors        │
│ • General Q&A  │  │ • Writing       │  │ • Circuits       │
├────────────────┤  ├─────────────────┤  ├──────────────────┤
│ Workspace:     │  │ Workspace:      │  │ Workspace:       │
│ /workspace     │  │ /workspace-     │  │ /workspace-      │
│                │  │  tutor-english  │  │  tutor-iot       │
└────────┬───────┘  └────────┬────────┘  └────────┬─────────┘
         │                   │                     │
         │                   │                     │
         ├───────────────────┴─────────────────────┤
         │                                         │
         ▼                                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                         OLLAMA API                               │
│                    (LLM Provider)                                │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Modelos:                                                 │  │
│  │  • llama3.2:latest (Primary)                             │  │
│  │  • llama3.1-fast:latest (Fast)                           │  │
│  │  • qwen3-vl:latest (Vision - opcional)                   │  │
│  │                                                            │  │
│  │  Configuração:                                            │  │
│  │  • Context: 8192 tokens                                   │  │
│  │  • Parallel: 2 requests                                   │  │
│  │  • Max Models: 1 in memory                                │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Fluxo de Mensagem Detalhado

### Exemplo 1: Pergunta sobre Inglês

```
[USUÁRIO]
    │
    │ "How do I use present perfect?"
    │
    ▼
[TELEGRAM BOT]
    │
    │ Envia para gateway via webhook
    │
    ▼
[GATEWAY]
    │
    │ Autentica → Rate limit check → Log
    │
    ▼
[ROUTING ENGINE]
    │
    ├─ Análise: "present perfect" → keyword match
    ├─ Confidence: 0.95 (alto)
    ├─ Decisão: Delegar para tutor-english
    │
    ▼
[TUTOR-ENGLISH]
    │
    ├─ Carrega system.md
    ├─ Consulta knowledge/grammar-rules.md
    ├─ Gera resposta via Ollama
    │
    ▼
[OLLAMA]
    │
    ├─ Modelo: llama3.2:latest
    ├─ Context: Histórico + System Prompt + Knowledge
    ├─ Gera: Explicação detalhada com exemplos
    │
    ▼
[TUTOR-ENGLISH]
    │
    │ Formata resposta com emojis e estrutura
    │
    ▼
[MAIN AGENT]
    │
    │ Consolida resposta (opcional)
    │
    ▼
[GATEWAY]
    │
    │ Serializa resposta
    │
    ▼
[TELEGRAM BOT]
    │
    │ Envia para usuário
    │
    ▼
[USUÁRIO]
    │
    │ Recebe: "📚 Present Perfect - Vou te explicar!
    │          
    │          O Present Perfect é usado para...
    │          
    │          ✅ Exemplo: I have studied English for 5 years.
    │          ❌ Erro comum: I have went → I have gone"
```

---

### Exemplo 2: Pergunta sobre IoT

```
[USUÁRIO]
    │
    │ "Como conectar sensor DHT22 no ESP32?"
    │
    ▼
[TELEGRAM BOT] → [GATEWAY] → [ROUTING ENGINE]
    │
    ├─ Análise: "sensor", "DHT22", "ESP32" → keywords match
    ├─ Confidence: 0.98 (muito alto)
    ├─ Decisão: Delegar para tutor-iot
    │
    ▼
[TUTOR-IOT]
    │
    ├─ Carrega system.md
    ├─ Consulta knowledge/sensor-database.json
    ├─ Consulta knowledge/esp32-pinout.md
    ├─ Gera código Arduino + diagrama de conexões
    │
    ▼
[OLLAMA] → Gera resposta completa
    ▼
[TUTOR-IOT] → Formata com código comentado
    ▼
[GATEWAY] → [TELEGRAM BOT]
    │
    ▼
[USUÁRIO]
    │
    │ Recebe: "🔌 Conexões DHT22 com ESP32:
    │          VCC → 3.3V
    │          DATA → GPIO4 (com pull-up 10kΩ)
    │          GND → GND
    │          
    │          ```cpp
    │          #include <DHT.h>
    │          #define DHTPIN 4
    │          ...
    │          ```
    │          
    │          💡 DHT22 precisa pull-up 10kΩ entre DATA e VCC"
```

---

### Exemplo 3: Menção Direta

```
[USUÁRIO]
    │
    │ "@tutor-iot: ESP32 I2C pinout?"
    │
    ▼
[ROUTING ENGINE]
    │
    ├─ Detecta padrão: @agent-id
    ├─ Parse: agent=tutor-iot, msg="ESP32 I2C pinout?"
    ├─ Decisão: Delegação direta (bypass keyword analysis)
    │
    ▼
[TUTOR-IOT] → Resposta imediata
```

---

## 🗂️ Estrutura de Dados

### Message Object

```json
{
  "id": "msg_123456",
  "timestamp": "2026-02-28T20:00:00Z",
  "user": {
    "id": "telegram_user_id",
    "name": "João Silva"
  },
  "content": {
    "text": "How do I use present perfect?",
    "type": "text"
  },
  "routing": {
    "sourceAgent": "main",
    "targetAgent": "tutor-english",
    "confidence": 0.95,
    "keywords": ["present", "perfect"],
    "strategy": "keyword-match"
  },
  "context": {
    "conversationId": "conv_abc123",
    "history": [...],
    "userPreferences": {}
  }
}
```

### Agent Response

```json
{
  "agentId": "tutor-english",
  "agentName": "English Tutor",
  "timestamp": "2026-02-28T20:00:05Z",
  "content": {
    "text": "📚 Present Perfect - Vou te explicar!...",
    "format": "markdown"
  },
  "metadata": {
    "modelUsed": "ollama/llama3.2:latest",
    "tokensUsed": 450,
    "processingTime": 2.3,
    "knowledgeBaseUsed": [
      "knowledge/grammar-rules.md"
    ]
  },
  "status": "success"
}
```

---

## 🔐 Isolation e Segurança

### Workspace Isolation

```
Cada agente tem seu próprio workspace isolado:

/home/openclaw/.openclaw/
├── workspace/              ← Main Agent
│   ├── tmp/
│   ├── cache/
│   └── sessions/
│
├── workspace-tutor-english/ ← English Tutor
│   ├── tmp/
│   ├── cache/
│   └── exercises/          ← Arquivos gerados
│
└── workspace-tutor-iot/    ← IoT Tutor
    ├── tmp/
    ├── cache/
    └── projects/           ← Código gerado
```

**Benefícios:**
- ✅ Sem conflito de arquivos
- ✅ Limpeza independente
- ✅ Backup granular
- ✅ Debugging facilitado

### Docker Network Isolation

```
networks:
  openclaw-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.18.0.0/16

Services:
├─ openclaw    → 172.18.0.2
├─ ollama      → 172.18.0.3
└─ nginx       → 172.18.0.4

Comunicação interna apenas.
Exposição externa: apenas nginx (80/443)
```

---

## 📊 Performance e Escalabilidade

### Concurrent Requests

```
Configuração atual:
├─ Gateway: max 10 concurrent connections
├─ Agents: max 4 concurrent per agent
├─ Ollama: max 2 parallel inferences
└─ Total capacity: ~8-12 req/s
```

### Resource Allocation

```
Container       CPU     Memory    Priority
─────────────────────────────────────────
openclaw        2 core  2GB       High
ollama          4 core  8GB       Critical
nginx           0.5 cor 256MB     Medium
─────────────────────────────────────────
Total           6.5 cor 10.25GB
```

### Optimization Tips

1. **Context Window**: Reduzir se necessário
   ```yaml
   OLLAMA_CONTEXT_LENGTH=4096  # ao invés de 8192
   ```

2. **Model Caching**: Manter modelo carregado
   ```yaml
   OLLAMA_MAX_LOADED_MODELS=1
   ```

3. **Request Queuing**: Evitar overload
   ```yaml
   OLLAMA_MAX_QUEUE=10
   ```

---

## 🎯 Métricas e Monitoramento

### Key Metrics

```
1. Response Time
   ├─ Gateway: < 50ms
   ├─ Routing: < 100ms
   ├─ Agent Processing: < 2s
   └─ Total: < 3s

2. Accuracy
   ├─ Routing: > 95% correct agent selection
   ├─ Response Quality: User feedback
   └─ Hallucination Rate: < 5%

3. Availability
   ├─ Uptime: > 99.5%
   ├─ Error Rate: < 0.5%
   └─ Recovery Time: < 30s
```

### Logging Structure

```
logs/
├── openclaw.log             # Gateway + routing
├── agents/
│   ├── main/
│   │   └── 2026-02-28.log
│   ├── tutor-english/
│   │   └── 2026-02-28.log
│   └── tutor-iot/
│       └── 2026-02-28.log
└── ollama/
    └── 2026-02-28.log
```

---

## 🔄 Ciclo de Vida de uma Conversa

```
1. Início
   ├─ Usuário: /start
   ├─ Create conversation_id
   ├─ Initialize context
   └─ Route to main agent

2. Interação
   ├─ Message received
   ├─ Routing decision
   ├─ Agent processes
   ├─ Response generated
   └─ Context updated

3. Delegação
   ├─ Main detects specialized topic
   ├─ Delegate to specialist
   ├─ Specialist processes
   ├─ Return to main
   └─ Main consolidates

4. Término
   ├─ User: /reset or timeout
   ├─ Archive conversation
   ├─ Clear workspace cache
   └─ Log metrics
```

---

## 🚀 Extensibilidade

### Adicionar Novo Agente

```bash
1. Criar estrutura
   mkdir -p agents/novo-agente/agent/{knowledge,tools}

2. Definir system prompt
   agents/novo-agente/agent/system.md

3. Registrar em openclaw.json
   {
     "id": "novo-agente",
     "keywords": [...],
     ...
   }

4. Restart
   docker-compose restart openclaw
```

### Adicionar Nova Ferramenta

```javascript
// agents/tutor-iot/agent/tools/circuit-validator.js
module.exports = {
  name: 'circuit-validator',
  description: 'Valida circuitos elétricos',
  
  async execute(circuit) {
    // Lógica de validação
    return {
      valid: true,
      warnings: []
    };
  }
};
```

### Integrar API Externa

```json
// openclaw.json
{
  "plugins": {
    "allow": [
      "telegram",
      "memory-core",
      "github-api"  // ← Nova API
    ],
    "entries": {
      "github-api": {
        "enabled": true,
        "token": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

---

*Diagrama criado em: 2026-02-28*  
*Versão: 1.0*
