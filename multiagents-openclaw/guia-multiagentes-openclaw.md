# 🤖 Guia de Configuração de Multiagentes no OpenClaw

## 📋 Sumário
1. [Visão Geral da Arquitetura](#visão-geral)
2. [Estrutura Atual vs Proposta](#estrutura)
3. [Configuração dos Agentes](#configuração)
4. [Scripts de Automação](#scripts)
5. [Integração com Telegram](#telegram)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral da Arquitetura

### Agentes Propostos

```
┌─────────────────────────────────────────┐
│           AGENT MAIN (Router)           │
│  - Roteamento de conversas              │
│  - Gerenciamento de contexto global     │
│  - Decisão de delegação                 │
└─────────────┬───────────────────────────┘
              │
      ┌───────┴───────┐
      │               │
┌─────▼─────┐   ┌────▼──────┐
│  TUTOR-   │   │  TUTOR-   │
│  ENGLISH  │   │    IOT    │
│           │   │           │
│ - Grammar │   │ - Arduino │
│ - Vocab   │   │ - ESP32   │
│ - Writing │   │ - Sensors │
└───────────┘   └───────────┘
```

### Fluxo de Comunicação

1. **Usuário → Main Agent**: Mensagem inicial
2. **Main Agent → Análise**: Identifica o domínio (inglês, IoT, geral)
3. **Main Agent → Delegação**: Aciona subagente especializado se necessário
4. **Subagente → Processamento**: Executa tarefa especializada
5. **Subagente → Main Agent**: Retorna resultado
6. **Main Agent → Usuário**: Resposta final unificada

---

## 📁 Estrutura Atual vs Proposta

### ✅ Estrutura Atual (Detectada)
```
openclaw-docker/
├── data/
│   └── .openclaw/
│       ├── agents/
│       │   └── main/
│       │       └── agent/
│       ├── config/
│       ├── workspace/
│       └── workspace-tutor-*/
├── docker-compose.yml
├── Dockerfile
├── entrypoint.sh
└── custom-config.yaml
```

### 🎯 Estrutura Proposta (Completa)
```
openclaw-docker/
├── data/
│   └── .openclaw/
│       ├── agents/
│       │   ├── main/
│       │   │   ├── agent/
│       │   │   │   ├── system.md          # ← System prompt do main
│       │   │   │   ├── routing.json       # ← Regras de roteamento
│       │   │   │   └── tools/
│       │   │   └── logs/
│       │   ├── tutor-english/
│       │   │   ├── agent/
│       │   │   │   ├── system.md          # ← Especializado em inglês
│       │   │   │   ├── knowledge/
│       │   │   │   │   ├── grammar-rules.md
│       │   │   │   │   └── vocabulary-exercises.md
│       │   │   │   └── tools/
│       │   │   └── logs/
│       │   └── tutor-iot/
│       │       ├── agent/
│       │       │   ├── system.md          # ← Especializado em IoT
│       │       │   ├── knowledge/
│       │       │   │   ├── arduino-ref.md
│       │       │   │   ├── esp32-pinout.md
│       │       │   │   └── sensor-database.json
│       │       │   └── tools/
│       │       │       ├── code-validator.js
│       │       │       └── circuit-checker.js
│       │       └── logs/
│       ├── workspace/                     # ← Workspace do main
│       ├── workspace-tutor-english/       # ← Workspace isolado inglês
│       └── workspace-tutor-iot/           # ← Workspace isolado IoT
├── config/
│   ├── agents/
│   │   ├── main-config.yaml
│   │   ├── tutor-english-config.yaml
│   │   └── tutor-iot-config.yaml
│   └── routing-rules.yaml
├── scripts/
│   ├── setup-agents.sh
│   ├── init-agent.sh
│   └── monitor-agents.sh
└── docker-compose.yml
```

---

## ⚙️ Configuração dos Agentes

### 1. Atualizar `openclaw.json`

O seu arquivo atual já tem a estrutura básica, vamos apenas refiná-lo:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/llama3.2:latest",
        "fallbacks": [
          "ollama/llama3.1-fast:latest"
        ]
      },
      "heartbeat": {
        "every": "20m",
        "model": "ollama/llama3.2:latest",
        "target": "last"
      },
      "subagents": {
        "maxConcurrent": 3,
        "archiveAfterMinutes": 30,
        "model": "ollama/llama3.2:latest",
        "communicationMode": "api"
      },
      "sandbox": {
        "mode": "all",
        "isolationLevel": "workspace"
      },
      "routing": {
        "enabled": true,
        "strategy": "skill-based"
      }
    },
    "list": [
      {
        "id": "main",
        "name": "main",
        "role": "coordinator",
        "description": "Agente principal que roteia e coordena conversas",
        "workspace": "/home/openclaw/.openclaw/workspace",
        "agentDir": "/home/openclaw/.openclaw/agents/main/agent",
        "capabilities": [
          "routing",
          "general-conversation",
          "task-delegation",
          "context-management"
        ],
        "subagents": ["tutor-english", "tutor-iot"]
      },
      {
        "id": "tutor-english",
        "name": "tutor-english",
        "role": "specialist",
        "description": "Tutor especializado em ensino de inglês",
        "workspace": "/home/openclaw/.openclaw/workspace-tutor-english",
        "agentDir": "/home/openclaw/.openclaw/agents/tutor-english/agent",
        "capabilities": [
          "english-grammar",
          "vocabulary-teaching",
          "writing-assistance",
          "pronunciation-guide",
          "conversation-practice"
        ],
        "keywords": [
          "english",
          "inglês",
          "grammar",
          "gramática",
          "vocabulary",
          "vocabulário",
          "translate",
          "traduzir",
          "pronunciation",
          "pronúncia"
        ],
        "model": {
          "primary": "ollama/llama3.2:latest",
          "contextWindow": 8192
        }
      },
      {
        "id": "tutor-iot",
        "name": "tutor-iot",
        "role": "specialist",
        "description": "Tutor especializado em IoT, Arduino e eletrônica",
        "workspace": "/home/openclaw/.openclaw/workspace-tutor-iot",
        "agentDir": "/home/openclaw/.openclaw/agents/tutor-iot/agent",
        "capabilities": [
          "arduino-programming",
          "esp32-development",
          "circuit-design",
          "sensor-integration",
          "iot-protocols",
          "troubleshooting"
        ],
        "keywords": [
          "arduino",
          "esp32",
          "sensor",
          "circuit",
          "circuito",
          "iot",
          "mqtt",
          "gpio",
          "i2c",
          "spi",
          "led",
          "motor",
          "servo"
        ],
        "model": {
          "primary": "ollama/llama3.2:latest",
          "contextWindow": 8192
        }
      }
    ]
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist",
      "streaming": "off",
      "routing": {
        "enabled": true,
        "defaultAgent": "main",
        "allowUserSelection": true
      }
    }
  }
}
```

### 2. System Prompts para Cada Agente

#### 📄 `agents/main/agent/system.md`

```markdown
# Main Agent - Coordenador e Roteador

## Identidade
Você é o agente principal do sistema OpenClaw. Sua função é:
1. Receber e analisar todas as mensagens dos usuários
2. Decidir se pode responder diretamente ou precisa delegar
3. Rotear para agentes especializados quando necessário
4. Consolidar respostas e manter contexto global

## Agentes Disponíveis

### tutor-english
- **Especialidade**: Ensino de inglês, gramática, vocabulário
- **Delegar quando**: Usuário pedir ajuda com inglês, tradução, exercícios
- **Keywords**: english, inglês, grammar, vocabulary, translate

### tutor-iot
- **Especialidade**: IoT, Arduino, ESP32, eletrônica, sensores
- **Delegar quando**: Usuário pedir código Arduino, ajuda com sensores, circuitos
- **Keywords**: arduino, esp32, sensor, iot, circuito, led, motor

## Estratégia de Roteamento

1. **Análise de Intenção**
   - Identifique o domínio da pergunta
   - Busque keywords conhecidas
   - Avalie a complexidade

2. **Decisão**
   - Resposta direta: Conversas gerais, saudações, perguntas simples
   - Delegação: Tópicos especializados que exigem conhecimento profundo

3. **Delegação**
   ```
   @tutor-english: [contexto resumido da pergunta]
   ```
   ou
   ```
   @tutor-iot: [contexto resumido da pergunta]
   ```

4. **Consolidação**
   - Receba a resposta do subagente
   - Adicione contexto se necessário
   - Mantenha o tom conversacional

## Tom e Estilo
- Profissional mas acessível
- Claro e objetivo
- Empático com as necessidades do usuário
- Transparente sobre delegações ("Vou consultar o especialista em...")

## Regras
- SEMPRE identifique o agente correto antes de delegar
- NÃO tente responder perguntas técnicas especializadas sem delegar
- MANTENHA registro do histórico de delegações
- Se houver dúvida, pergunte ao usuário para esclarecer
```

#### 📄 `agents/tutor-english/agent/system.md`

```markdown
# English Tutor Agent

## Identidade
Você é um tutor especializado em ensino de inglês. Seu objetivo é ajudar usuários brasileiros a aprenderem inglês de forma eficaz e prática.

## Especialidades
1. **Gramática**: Explicar regras, corrigir erros, exemplificar
2. **Vocabulário**: Ensinar palavras novas, contextos de uso, expressões idiomáticas
3. **Escrita**: Revisar textos, sugerir melhorias, ensinar estruturas
4. **Conversação**: Praticar diálogos, corrigir pronúncia (via texto fonético)
5. **Tradução**: Traduzir com explicações contextuais

## Metodologia de Ensino

### Para Gramática
1. Explique a regra em português
2. Dê 2-3 exemplos claros
3. Mostre o erro comum e a correção
4. Forneça exercício prático

Exemplo:
```
❌ Erro: "I go to school yesterday"
✅ Correto: "I went to school yesterday"

📚 Regra: Usamos o Simple Past (went) para ações concluídas no passado.
```

### Para Vocabulário
1. Palavra em inglês + pronúncia (IPA ou simplificada)
2. Tradução(ões) em português
3. Exemplo em contexto
4. Sinônimos ou palavras relacionadas

Exemplo:
```
📖 **accomplish** /əˈkʌmplɪʃ/
🇧🇷 realizar, concluir, alcançar

💬 "She accomplished her goal of learning English."
    (Ela realizou seu objetivo de aprender inglês.)

🔗 Relacionadas: achieve, complete, fulfill
```

### Para Correções
- Use emojis: ❌ para erro, ✅ para correção
- SEMPRE explique o porquê da correção
- Seja gentil e encorajador
- Ofereça alternativas quando possível

## Tom e Estilo
- Encorajador e paciente
- Didático mas não condescendente
- Use exemplos práticos e relevantes
- Adapte a complexidade ao nível do aluno

## Recursos Disponíveis
- Base de conhecimento em `knowledge/grammar-rules.md`
- Exercícios em `knowledge/vocabulary-exercises.md`
- Dicionário de expressões idiomáticas

## Regras
- NUNCA corrija em português se não for solicitado
- SEMPRE dê feedback construtivo
- SE não souber algo, seja honesto
- ADAPTE o nível de dificuldade ao aluno
```

#### 📄 `agents/tutor-iot/agent/system.md`

```markdown
# IoT & Arduino Tutor Agent

## Identidade
Você é um especialista em IoT, Arduino, ESP32 e eletrônica embarcada. Seu objetivo é ensinar, guiar e resolver problemas técnicos relacionados ao desenvolvimento de projetos IoT.

## Especialidades
1. **Arduino**: Programação, bibliotecas, troubleshooting
2. **ESP32**: WiFi, Bluetooth, recursos avançados
3. **Sensores**: Integração, calibração, leitura de dados
4. **Circuitos**: Design, análise, correção de problemas
5. **Protocolos**: MQTT, HTTP, I2C, SPI, UART
6. **Projetos**: Arquitetura, melhores práticas, otimização

## Metodologia de Ensino

### Para Código Arduino
1. Forneça código completo e funcional
2. Comente cada seção importante
3. Explique a lógica por trás
4. Indique alternativas ou melhorias

Exemplo:
```cpp
// ========================================
// Leitura de Sensor DHT22
// ========================================
#include <DHT.h>

#define DHTPIN 4        // Pino de dados conectado ao GPIO4
#define DHTTYPE DHT22   // Tipo do sensor

DHT dht(DHTPIN, DHTTYPE);

void setup() {
  Serial.begin(115200);
  dht.begin();
  Serial.println("DHT22 inicializado!");
}

void loop() {
  float temp = dht.readTemperature();  // Lê temperatura em °C
  float umid = dht.readHumidity();     // Lê umidade em %

  // Verifica se a leitura foi bem-sucedida
  if (isnan(temp) || isnan(umid)) {
    Serial.println("❌ Erro na leitura do sensor!");
    return;
  }

  // Exibe os valores
  Serial.print("🌡️ Temp: ");
  Serial.print(temp);
  Serial.print("°C | 💧 Umid: ");
  Serial.print(umid);
  Serial.println("%");

  delay(2000);  // Aguarda 2 segundos antes da próxima leitura
}

// 💡 Dica: O DHT22 precisa de pull-up resistor de 10kΩ entre DATA e VCC
```

### Para Circuitos
1. Descreva a conexão passo a passo
2. Use formato de lista clara
3. Alerte sobre polaridades e tensões
4. Sugira esquemático ASCII quando útil

Exemplo:
```
🔌 Conexões do LED RGB com ESP32:

LED RGB (Catodo Comum):
├─ Pino Vermelho  → GPIO25 (via resistor 220Ω)
├─ Pino Verde     → GPIO26 (via resistor 220Ω)
├─ Pino Azul      → GPIO27 (via resistor 220Ω)
└─ Pino Comum (−) → GND

⚠️ IMPORTANTE:
- SEMPRE use resistores (220Ω - 330Ω)
- Verifique se é catodo ou anodo comum
- ESP32 opera em 3.3V (não conecte 5V diretamente!)
```

### Para Troubleshooting
1. Identifique o sintoma
2. Liste causas possíveis (mais comuns primeiro)
3. Forneça passo a passo de diagnóstico
4. Ofereça soluções testadas

Exemplo:
```
🐛 Problema: "Sensor não responde"

Diagnóstico passo a passo:

1️⃣ **Verificar alimentação**
   - Sensor recebe 3.3V ou 5V corretamente?
   - GND está conectado?

2️⃣ **Verificar conexão de dados**
   - Cabo íntegro?
   - Pino correto do microcontrolador?

3️⃣ **Testar comunicação**
   ```cpp
   Wire.beginTransmission(0x76);  // Endereço I2C do sensor
   if (Wire.endTransmission() == 0) {
     Serial.println("✅ Sensor detectado!");
   } else {
     Serial.println("❌ Sensor não encontrado.");
   }
   ```

4️⃣ **Verificar biblioteca**
   - Versão compatível instalada?
   - Exemplo da biblioteca funciona?
```

## Recursos Disponíveis
- Pinout do ESP32 em `knowledge/esp32-pinout.md`
- Referência Arduino em `knowledge/arduino-ref.md`
- Database de sensores em `knowledge/sensor-database.json`
- Validador de código em `tools/code-validator.js`

## Tom e Estilo
- Técnico mas acessível
- Prático e orientado a soluções
- Use emojis para facilitar escaneamento visual
- Compartilhe boas práticas da indústria

## Regras
- SEMPRE forneça código testável
- NUNCA sugira conexões perigosas (curto-circuito, sobretensão)
- INCLUA comentários em português no código
- ALERTE sobre precauções de segurança quando relevante
```

---

## 🚀 Scripts de Automação

### 📄 `scripts/setup-agents.sh`

```bash
#!/bin/bash
# ====================================================
# Setup de Multiagentes OpenClaw
# Cria estrutura de diretórios e arquivos de configuração
# ====================================================

set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-/home/openclaw/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo -e "\033[0;32m[setup]\033[0m $1"; }
warn() { echo -e "\033[1;33m[setup]\033[0m $1"; }
error() { echo -e "\033[0;31m[setup]\033[0m $1" >&2; }

# ====================================================
# Função: Criar estrutura de diretórios
# ====================================================
create_agent_structure() {
    local agent_id=$1
    local agent_name=$2
    local description=$3
    
    log "📁 Criando estrutura para agente: $agent_name"
    
    local agent_dir="${OPENCLAW_HOME}/agents/${agent_id}/agent"
    local workspace="${OPENCLAW_HOME}/workspace-${agent_id}"
    
    # Criar diretórios
    mkdir -p "$agent_dir"/{knowledge,tools,logs}
    mkdir -p "$workspace"
    
    # Criar arquivo de metadados
    cat > "$agent_dir/agent.json" <<EOF
{
  "id": "$agent_id",
  "name": "$agent_name",
  "description": "$description",
  "version": "1.0.0",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "workspace": "$workspace"
}
EOF
    
    log "✅ Estrutura criada em: $agent_dir"
}

# ====================================================
# Função: Criar system prompt
# ====================================================
create_system_prompt() {
    local agent_id=$1
    local prompt_file=$2
    
    log "📝 Criando system prompt para: $agent_id"
    
    local agent_dir="${OPENCLAW_HOME}/agents/${agent_id}/agent"
    
    if [ ! -f "$prompt_file" ]; then
        warn "⚠️  Arquivo de prompt não encontrado: $prompt_file"
        warn "   Criando placeholder..."
        
        cat > "$agent_dir/system.md" <<EOF
# ${agent_id^} Agent

## Identidade
[Definir a identidade e propósito do agente]

## Especialidades
[Listar áreas de especialização]

## Metodologia
[Descrever como o agente deve abordar tarefas]

## Recursos Disponíveis
- Base de conhecimento em \`knowledge/\`
- Ferramentas em \`tools/\`

## Regras
[Definir regras e restrições]
EOF
    else
        cp "$prompt_file" "$agent_dir/system.md"
    fi
    
    log "✅ System prompt criado"
}

# ====================================================
# Função: Inicializar knowledge base
# ====================================================
init_knowledge_base() {
    local agent_id=$1
    shift
    local kb_files=("$@")
    
    log "📚 Inicializando knowledge base para: $agent_id"
    
    local kb_dir="${OPENCLAW_HOME}/agents/${agent_id}/agent/knowledge"
    
    for kb_file in "${kb_files[@]}"; do
        if [ -f "$kb_file" ]; then
            cp "$kb_file" "$kb_dir/"
            log "   ✓ Copiado: $(basename "$kb_file")"
        else
            warn "   ⚠️  Não encontrado: $kb_file"
        fi
    done
    
    # Criar índice
    cat > "$kb_dir/index.md" <<EOF
# Knowledge Base Index

## Arquivos Disponíveis
$(ls -1 "$kb_dir" | grep -v index.md | sed 's/^/- /')

Última atualização: $(date)
EOF
    
    log "✅ Knowledge base inicializada"
}

# ====================================================
# MAIN
# ====================================================
main() {
    log "🚀 Iniciando setup de multiagentes OpenClaw"
    log "   Home: $OPENCLAW_HOME"
    
    # Verificar se OpenClaw está instalado
    if ! command -v openclaw &> /dev/null; then
        error "❌ OpenClaw não encontrado. Instale primeiro."
        exit 1
    fi
    
    # 1. Agente Main (já existe, apenas validar)
    log "\n=== Agente: main ==="
    if [ -d "${OPENCLAW_HOME}/agents/main" ]; then
        log "✅ Agente main já existe"
    else
        create_agent_structure "main" "Main Coordinator" "Agente principal que roteia conversas"
        create_system_prompt "main" "${SCRIPT_DIR}/../config/agents/main-system.md"
    fi
    
    # 2. Tutor English
    log "\n=== Agente: tutor-english ==="
    create_agent_structure "tutor-english" "English Tutor" "Tutor especializado em ensino de inglês"
    create_system_prompt "tutor-english" "${SCRIPT_DIR}/../config/agents/tutor-english-system.md"
    init_knowledge_base "tutor-english" \
        "${SCRIPT_DIR}/../knowledge/english/grammar-rules.md" \
        "${SCRIPT_DIR}/../knowledge/english/vocabulary-exercises.md"
    
    # 3. Tutor IoT
    log "\n=== Agente: tutor-iot ==="
    create_agent_structure "tutor-iot" "IoT Tutor" "Especialista em IoT, Arduino e eletrônica"
    create_system_prompt "tutor-iot" "${SCRIPT_DIR}/../config/agents/tutor-iot-system.md"
    init_knowledge_base "tutor-iot" \
        "${SCRIPT_DIR}/../knowledge/iot/arduino-ref.md" \
        "${SCRIPT_DIR}/../knowledge/iot/esp32-pinout.md" \
        "${SCRIPT_DIR}/../knowledge/iot/sensor-database.json"
    
    # 4. Ajustar permissões
    log "\n📁 Ajustando permissões..."
    chown -R openclaw:openclaw "${OPENCLAW_HOME}/agents"
    chown -R openclaw:openclaw "${OPENCLAW_HOME}/workspace"*
    chmod -R 750 "${OPENCLAW_HOME}/agents"
    
    # 5. Verificar configuração
    log "\n🔍 Verificando configuração..."
    openclaw doctor || warn "⚠️  Alguns checks falharam (pode ser normal)"
    
    log "\n✨ Setup concluído com sucesso!"
    log "\nPróximos passos:"
    log "1. Edite os system prompts em: ${OPENCLAW_HOME}/agents/*/agent/system.md"
    log "2. Adicione knowledge base em: ${OPENCLAW_HOME}/agents/*/agent/knowledge/"
    log "3. Reinicie o OpenClaw: docker-compose restart openclaw"
    log "4. Teste os agentes via Telegram ou gateway"
}

main "$@"
```

### 📄 `scripts/init-agent.sh`

```bash
#!/bin/bash
# ====================================================
# Inicializar um novo agente no OpenClaw
# Uso: ./init-agent.sh <agent-id> <agent-name> <description>
# ====================================================

set -euo pipefail

if [ $# -lt 3 ]; then
    echo "Uso: $0 <agent-id> <agent-name> <description>"
    echo "Exemplo: $0 tutor-math 'Math Tutor' 'Tutor de matemática'"
    exit 1
fi

AGENT_ID=$1
AGENT_NAME=$2
AGENT_DESC=$3

OPENCLAW_HOME="${OPENCLAW_HOME:-/home/openclaw/.openclaw}"

log() { echo -e "\033[0;32m[init]\033[0m $1"; }

log "🆕 Criando novo agente: $AGENT_NAME ($AGENT_ID)"

# Criar estrutura
mkdir -p "${OPENCLAW_HOME}/agents/${AGENT_ID}/agent"/{knowledge,tools,logs}
mkdir -p "${OPENCLAW_HOME}/workspace-${AGENT_ID}"

# Criar system.md
cat > "${OPENCLAW_HOME}/agents/${AGENT_ID}/agent/system.md" <<EOF
# $AGENT_NAME

## Identidade
$AGENT_DESC

## Especialidades
[Definir especialidades]

## Metodologia
[Definir metodologia]

## Regras
[Definir regras]
EOF

# Criar agent.json
cat > "${OPENCLAW_HOME}/agents/${AGENT_ID}/agent/agent.json" <<EOF
{
  "id": "$AGENT_ID",
  "name": "$AGENT_NAME",
  "description": "$AGENT_DESC",
  "version": "1.0.0",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Adicionar ao openclaw.json
log "📝 Atualizando openclaw.json..."
# (Aqui você pode usar jq para modificar o JSON programaticamente)

log "✅ Agente criado com sucesso!"
log "   Diretório: ${OPENCLAW_HOME}/agents/${AGENT_ID}"
log "   Workspace: ${OPENCLAW_HOME}/workspace-${AGENT_ID}"
log "\nPróximos passos:"
log "1. Edite: ${OPENCLAW_HOME}/agents/${AGENT_ID}/agent/system.md"
log "2. Adicione knowledge em: ${OPENCLAW_HOME}/agents/${AGENT_ID}/agent/knowledge/"
log "3. Registre no openclaw.json"
log "4. Reinicie: docker-compose restart openclaw"
```

### 📄 `scripts/monitor-agents.sh`

```bash
#!/bin/bash
# ====================================================
# Monitor de status dos agentes OpenClaw
# ====================================================

set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-/home/openclaw/.openclaw}"

log() { echo -e "\033[0;32m[monitor]\033[0m $1"; }

clear
echo "╔══════════════════════════════════════════════╗"
echo "║     OpenClaw Multiagent Monitor              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Listar agentes
echo "📋 Agentes Registrados:"
echo ""

for agent_dir in "${OPENCLAW_HOME}/agents"/*/; do
    agent_id=$(basename "$agent_dir")
    
    # Ler metadados
    if [ -f "$agent_dir/agent/agent.json" ]; then
        agent_name=$(jq -r '.name // "N/A"' "$agent_dir/agent/agent.json" 2>/dev/null || echo "N/A")
        agent_desc=$(jq -r '.description // "N/A"' "$agent_dir/agent/agent.json" 2>/dev/null || echo "N/A")
    else
        agent_name="N/A"
        agent_desc="N/A"
    fi
    
    # Verificar logs recentes
    log_count=$(find "$agent_dir/logs" -name "*.log" 2>/dev/null | wc -l || echo 0)
    
    # Verificar workspace
    workspace_size=$(du -sh "${OPENCLAW_HOME}/workspace-${agent_id}" 2>/dev/null | cut -f1 || echo "N/A")
    
    echo "┌─ $agent_id"
    echo "│  Nome: $agent_name"
    echo "│  Descrição: $agent_desc"
    echo "│  Logs: $log_count arquivos"
    echo "│  Workspace: $workspace_size"
    echo "└─"
    echo ""
done

# Status do gateway
echo "🌐 Gateway Status:"
if curl -sf http://localhost:18790/ >/dev/null 2>&1; then
    echo "   ✅ Gateway rodando (porta 18790)"
else
    echo "   ❌ Gateway offline"
fi
echo ""

# Status do Ollama
echo "🤖 Ollama Status:"
if curl -sf "${OLLAMA_API_BASE:-http://localhost:11434}/api/tags" >/dev/null 2>&1; then
    echo "   ✅ Ollama conectado"
    ollama_models=$(curl -sf "${OLLAMA_API_BASE:-http://localhost:11434}/api/tags" | jq -r '.models[].name' 2>/dev/null | wc -l || echo 0)
    echo "   📦 Modelos disponíveis: $ollama_models"
else
    echo "   ❌ Ollama offline"
fi
echo ""

# Telegram
echo "📱 Telegram Bot:"
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
    echo "   ✅ Token configurado"
else
    echo "   ⚠️  Token não configurado"
fi
echo ""

log "Pressione Ctrl+C para sair. Atualizando a cada 5s..."
sleep 5
exec "$0"
```

---

## 📱 Integração com Telegram

### Comandos para Usuários

Configure os comandos no BotFather:

```
start - Inicia uma conversa
help - Mostra ajuda e comandos disponíveis
agent - Seleciona um agente específico
status - Mostra status dos agentes
reset - Reseta a conversa atual
```

### Fluxo de Interação

```
Usuário: /start
Bot: 👋 Olá! Sou o assistente OpenClaw.
     Posso ajudar com:
     • 🇬🇧 Inglês (gramática, vocabulário, tradução)
     • 🤖 IoT (Arduino, ESP32, sensores)
     • 💬 Conversas gerais
     
     Como posso ajudar hoje?

Usuário: Preciso de ajuda com o present perfect
Bot: 📨 Encaminhando para o tutor de inglês...

[Tutor English]: 📚 Present Perfect - Vou te explicar!

O Present Perfect é usado para ações que...
[resposta completa]

Usuário: @tutor-iot Como faço para ler um sensor DHT22?
[Tutor IoT]: 🔧 Vou te mostrar como conectar e programar...

[código completo]
```

### Menção Direta de Agentes

Usuários podem mencionar agentes diretamente:

```
@tutor-english: How do I use "have been" vs "has been"?
@tutor-iot: Show me ESP32 pinout for I2C
```

---

## 🔧 Troubleshooting

### Problema 1: Agente não responde

**Sintomas**: Mensagem enviada, mas sem resposta

**Diagnóstico**:
```bash
# 1. Verificar logs do agente
docker exec -it openclaw tail -f /home/openclaw/.openclaw/agents/tutor-english/logs/latest.log

# 2. Verificar gateway
curl http://localhost:18790/

# 3. Verificar Ollama
curl http://localhost:11434/api/tags
```

**Soluções**:
- Reinicie o container: `docker-compose restart openclaw`
- Verifique conectividade Ollama
- Valide `openclaw.json`

### Problema 2: Roteamento incorreto

**Sintomas**: Agente errado responde

**Diagnóstico**:
```bash
# Verificar keywords no openclaw.json
cat /home/openclaw/.openclaw/openclaw.json | jq '.agents.list[].keywords'
```

**Soluções**:
- Ajuste as keywords em `openclaw.json`
- Refine o system prompt do main agent
- Adicione mais contexto na mensagem

### Problema 3: Knowledge base não carregada

**Sintomas**: Agente não usa conhecimento específico

**Diagnóstico**:
```bash
# Verificar estrutura
ls -la /home/openclaw/.openclaw/agents/tutor-iot/agent/knowledge/

# Verificar permissões
ls -l /home/openclaw/.openclaw/agents/*/agent/knowledge/
```

**Soluções**:
- Ajuste permissões: `chown -R 1000:1000 /path/to/knowledge`
- Verifique formato dos arquivos (.md, .json)
- Reinicialize o agente

### Problema 4: Workspace isolation não funciona

**Sintomas**: Agentes compartilham arquivos indevidamente

**Diagnóstico**:
```bash
# Verificar workspace paths
cat /home/openclaw/.openclaw/openclaw.json | jq '.agents.list[].workspace'

# Verificar montagem de volumes
docker inspect openclaw | jq '.[0].Mounts'
```

**Soluções**:
- Confirme paths corretos em `openclaw.json`
- Valide volumes no `docker-compose.yml`
- Recrie workspaces: `rm -rf workspace-* && ./scripts/setup-agents.sh`

---

## 📚 Próximos Passos

1. **Implementar Tools Customizados**
   - Code validator para tutor-iot
   - Grammar checker para tutor-english

2. **Adicionar Persistência**
   - SQLite para histórico de conversas
   - Cache de respostas frequentes

3. **Monitoramento e Analytics**
   - Dashboard com métricas
   - Logs estruturados (JSON)

4. **Testes Automatizados**
   - Unit tests para routing logic
   - Integration tests com mock Telegram

5. **Documentação Adicional**
   - API reference dos agentes
   - Cookbook com exemplos práticos

---

## 🆘 Suporte

- **Documentação OpenClaw**: https://docs.openclaw.com
- **Issues no GitHub**: https://github.com/openclaw/openclaw/issues
- **Telegram da Comunidade**: t.me/openclaw_community

---

*Última atualização: 2026-02-28*
