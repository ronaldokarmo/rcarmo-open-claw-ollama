#!/bin/bash
# ====================================================
# Setup Rápido de Multiagentes OpenClaw
# Uso: ./quick-setup-multiagent.sh
# ====================================================

set -euo pipefail

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[setup]${NC} $1"; }
warn() { echo -e "${YELLOW}[setup]${NC} $1"; }
error() { echo -e "${RED}[setup]${NC} $1" >&2; }
info() { echo -e "${BLUE}[info]${NC} $1"; }

# ====================================================
# Banner
# ====================================================
clear
cat << "EOF"
╔══════════════════════════════════════════════════╗
║                                                  ║
║     🤖 OpenClaw Multiagent Setup 🤖             ║
║                                                  ║
║  Configuração automática de múltiplos agentes   ║
║                                                  ║
╚══════════════════════════════════════════════════╝
EOF
echo ""

# ====================================================
# Verificar pré-requisitos
# ====================================================
log "🔍 Verificando pré-requisitos..."

# Docker
if ! command -v docker &> /dev/null; then
    error "❌ Docker não encontrado. Instale: https://docs.docker.com/get-docker/"
    exit 1
fi
log "✅ Docker instalado: $(docker --version | cut -d' ' -f3)"

# Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    error "❌ Docker Compose não encontrado."
    exit 1
fi
log "✅ Docker Compose instalado"

# jq (opcional mas recomendado)
if ! command -v jq &> /dev/null; then
    warn "⚠️  jq não instalado (opcional). Para instalar: sudo apt install jq"
else
    log "✅ jq instalado"
fi

echo ""

# ====================================================
# Variáveis
# ====================================================
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${PROJECT_ROOT}/data/.openclaw"
AGENTS_DIR="${DATA_DIR}/agents"

log "📁 Diretório do projeto: $PROJECT_ROOT"
log "📁 Diretório de dados: $DATA_DIR"
echo ""

# ====================================================
# Backup da configuração existente (se houver)
# ====================================================
if [ -f "${DATA_DIR}/openclaw.json" ]; then
    BACKUP_FILE="${DATA_DIR}/openclaw.json.backup.$(date +%Y%m%d_%H%M%S)"
    log "💾 Backup da configuração existente: $BACKUP_FILE"
    cp "${DATA_DIR}/openclaw.json" "$BACKUP_FILE"
fi

# ====================================================
# Criar estrutura de diretórios
# ====================================================
log "📁 Criando estrutura de diretórios..."

mkdir -p "$DATA_DIR"/{config,logs,workspace}
mkdir -p "$AGENTS_DIR"/{main,tutor-english,tutor-iot}/{agent,logs}
mkdir -p "$AGENTS_DIR"/main/agent/{knowledge,tools}
mkdir -p "$AGENTS_DIR"/tutor-english/agent/{knowledge,tools}
mkdir -p "$AGENTS_DIR"/tutor-iot/agent/{knowledge,tools}
mkdir -p "$DATA_DIR"/workspace{,-tutor-english,-tutor-iot}

log "✅ Estrutura criada"

# ====================================================
# Criar system prompts
# ====================================================
log "📝 Criando system prompts..."

# Main Agent
cat > "$AGENTS_DIR/main/agent/system.md" << 'EOFMAIN'
# Main Agent - Coordenador e Roteador

## Identidade
Você é o agente principal do sistema OpenClaw. Sua função é coordenar conversas e rotear para agentes especializados quando necessário.

## Agentes Disponíveis

### tutor-english
- **Especialidade**: Ensino de inglês, gramática, vocabulário, tradução
- **Delegar quando**: Perguntas sobre inglês, correções, exercícios
- **Exemplo**: "How do I use present perfect?" → Delegue para @tutor-english

### tutor-iot  
- **Especialidade**: IoT, Arduino, ESP32, sensores, eletrônica
- **Delegar quando**: Código Arduino, circuitos, troubleshooting de hardware
- **Exemplo**: "Como conectar sensor DHT22 no ESP32?" → Delegue para @tutor-iot

## Estratégia de Roteamento

1. **Análise**: Identifique palavras-chave e contexto
2. **Decisão**: 
   - Resposta direta → Conversas gerais, saudações
   - Delegação → Tópicos técnicos especializados
3. **Delegação**: Use `@agent-id: [mensagem]`
4. **Consolidação**: Integre a resposta mantendo contexto

## Tom
- Profissional mas acessível
- Claro e objetivo  
- Transparente sobre delegações
EOFMAIN

# English Tutor
cat > "$AGENTS_DIR/tutor-english/agent/system.md" << 'EOFENGLISH'
# English Tutor Agent

## Identidade
Tutor especializado em ensino de inglês para brasileiros.

## Especialidades
- Gramática e correções
- Vocabulário e expressões
- Escrita e revisão de textos
- Conversação (simulação via texto)
- Tradução contextual

## Metodologia

### Correções
```
❌ Erro: "I go to school yesterday"
✅ Correto: "I went to school yesterday"

📚 Regra: Simple Past para ações passadas concluídas.
```

### Vocabulário  
```
📖 accomplish /əˈkʌmplɪʃ/
🇧🇷 realizar, concluir

💬 "She accomplished her goal."
   (Ela realizou seu objetivo.)
```

## Tom
- Encorajador e paciente
- Didático sem ser condescendente
- Use exemplos práticos
- Adapte ao nível do aluno

## Regras
- SEMPRE explique o porquê das correções
- Use emojis para clareza visual
- Seja gentil e construtivo
EOFENGLISH

# IoT Tutor
cat > "$AGENTS_DIR/tutor-iot/agent/system.md" << 'EOFIOT'
# IoT & Arduino Tutor Agent

## Identidade
Especialista em IoT, Arduino, ESP32 e eletrônica embarcada.

## Especialidades
- Programação Arduino/ESP32
- Integração de sensores
- Design de circuitos
- Protocolos (MQTT, I2C, SPI)
- Troubleshooting de hardware

## Metodologia

### Código Arduino
- Forneça código completo e funcional
- Comente cada seção importante
- Explique a lógica
- Indique melhorias possíveis

Exemplo:
```cpp
// Leitura de sensor DHT22
#include <DHT.h>

#define DHTPIN 4        // GPIO4
#define DHTTYPE DHT22

DHT dht(DHTPIN, DHTTYPE);

void setup() {
  Serial.begin(115200);
  dht.begin();
}

void loop() {
  float temp = dht.readTemperature();
  
  if (isnan(temp)) {
    Serial.println("❌ Erro na leitura!");
    return;
  }
  
  Serial.print("🌡️ Temp: ");
  Serial.print(temp);
  Serial.println("°C");
  
  delay(2000);
}

// 💡 DHT22 precisa pull-up 10kΩ entre DATA e VCC
```

### Circuitos
```
🔌 Conexões LED RGB (Catodo Comum):
├─ R → GPIO25 (via 220Ω)
├─ G → GPIO26 (via 220Ω)  
├─ B → GPIO27 (via 220Ω)
└─ − → GND

⚠️ SEMPRE use resistores!
```

## Tom
- Técnico mas acessível
- Prático e orientado a soluções
- Use emojis para organização visual
- Compartilhe boas práticas

## Regras
- SEMPRE forneça código testável
- NUNCA sugira conexões perigosas
- Comente em português
- Alerte sobre precauções de segurança
EOFIOT

log "✅ System prompts criados"

# ====================================================
# Criar agent.json para cada agente
# ====================================================
log "📋 Criando metadados dos agentes..."

# Main
cat > "$AGENTS_DIR/main/agent/agent.json" << EOF
{
  "id": "main",
  "name": "Main Coordinator",
  "description": "Agente principal que roteia conversas",
  "version": "1.0.0",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "role": "coordinator"
}
EOF

# English
cat > "$AGENTS_DIR/tutor-english/agent/agent.json" << EOF
{
  "id": "tutor-english",
  "name": "English Tutor",
  "description": "Tutor especializado em inglês",
  "version": "1.0.0",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "role": "specialist"
}
EOF

# IoT
cat > "$AGENTS_DIR/tutor-iot/agent/agent.json" << EOF
{
  "id": "tutor-iot",
  "name": "IoT Tutor",
  "description": "Especialista em IoT e Arduino",
  "version": "1.0.0",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "role": "specialist"
}
EOF

log "✅ Metadados criados"

# ====================================================
# Criar knowledge base básica
# ====================================================
log "📚 Criando knowledge base básica..."

# English knowledge
mkdir -p "$AGENTS_DIR/tutor-english/agent/knowledge"
cat > "$AGENTS_DIR/tutor-english/agent/knowledge/grammar-rules.md" << 'EOF'
# Grammar Rules Reference

## Present Perfect
- **Estrutura**: have/has + past participle
- **Uso**: Ações passadas com relevância no presente
- **Exemplo**: "I have studied English for 5 years."

## Simple Past vs Present Perfect
| Simple Past | Present Perfect |
|-------------|----------------|
| I lived in Brazil (não moro mais) | I have lived in Brazil (ainda moro) |
| Tempo específico no passado | Tempo não específico |

## Common Mistakes
1. ❌ "I have went" → ✅ "I have gone"
2. ❌ "He don't likes" → ✅ "He doesn't like"
3. ❌ "I am agree" → ✅ "I agree"
EOF

cat > "$AGENTS_DIR/tutor-english/agent/knowledge/vocabulary-exercises.md" << 'EOF'
# Vocabulary Exercises

## Daily Routine Verbs
- wake up - acordar
- get up - levantar
- have breakfast - tomar café da manhã
- go to work - ir ao trabalho

## Practice Sentence
"I ____ at 7am and ____ breakfast at 7:30am."
(wake up, have)
EOF

# IoT knowledge
mkdir -p "$AGENTS_DIR/tutor-iot/agent/knowledge"
cat > "$AGENTS_DIR/tutor-iot/agent/knowledge/esp32-pinout.md" << 'EOF'
# ESP32 DevKit v1 Pinout Reference

## GPIO Pins
- **Digital I/O**: GPIO 0-39
- **ADC**: GPIO 32-39 (ADC1), GPIO 0-10 (ADC2)
- **PWM**: Todos os GPIO (16 canais)
- **Touch**: GPIO 0, 2, 4, 12-15, 27, 32-33

## I2C (Default)
- **SDA**: GPIO 21
- **SCL**: GPIO 22

## SPI (Default)  
- **MOSI**: GPIO 23
- **MISO**: GPIO 19
- **SCK**: GPIO 18
- **SS**: GPIO 5

## UART
- **TX0**: GPIO 1
- **RX0**: GPIO 3

## ⚠️ Pinos de Input Only
GPIO 34-39 são INPUT ONLY (sem pull-up interno)
EOF

cat > "$AGENTS_DIR/tutor-iot/agent/knowledge/sensor-database.json" << 'EOF'
{
  "sensors": [
    {
      "name": "DHT22",
      "type": "temperature-humidity",
      "voltage": "3.3-5V",
      "protocol": "1-Wire",
      "library": "DHT sensor library by Adafruit",
      "pins": ["VCC", "DATA", "GND"],
      "notes": "Requer pull-up 10kΩ entre DATA e VCC"
    },
    {
      "name": "HC-SR04",
      "type": "ultrasonic",
      "voltage": "5V",
      "protocol": "Digital",
      "library": "NewPing",
      "pins": ["VCC", "TRIG", "ECHO", "GND"],
      "notes": "Echo pin requer divisor de tensão para ESP32 (3.3V)"
    }
  ]
}
EOF

log "✅ Knowledge base criada"

# ====================================================
# Ajustar permissões
# ====================================================
log "🔐 Ajustando permissões..."

# Se estiver rodando como root, ajustar para usuário 1000
if [ "$EUID" -eq 0 ]; then
    chown -R 1000:1000 "$DATA_DIR"
fi
chmod -R 750 "$DATA_DIR"

log "✅ Permissões ajustadas"

# ====================================================
# Verificar .env
# ====================================================
if [ ! -f "${PROJECT_ROOT}/.env" ]; then
    warn "⚠️  Arquivo .env não encontrado!"
    info "Criando .env de exemplo..."
    
    cat > "${PROJECT_ROOT}/.env" << 'EOFENV'
# Ollama
OLLAMA_API_BASE=http://ollama:11434
OLLAMA_API_KEY=ollama-local

# OpenClaw Gateway
OPENCLAW_GATEWAY_TOKEN=your-secure-token-here
OPENCLAW_GATEWAY_PASSWORD=your-secure-password-here
OPENCLAW_PORT=18790

# Telegram Bot
TELEGRAM_BOT_TOKEN=

# Optional APIs
GOOGLE_AI_KEY=
GROQ_API_KEY=
OPENROUTER_API_KEY=
BRAVE_API_KEY=
EOFENV
    
    warn "⚠️  Configure o .env antes de iniciar!"
    warn "   Especialmente: TELEGRAM_BOT_TOKEN"
fi

# ====================================================
# Resumo
# ====================================================
echo ""
log "✅ Setup concluído com sucesso!"
echo ""
info "📋 Estrutura criada:"
info "   ├─ agents/main/          (Coordenador)"
info "   ├─ agents/tutor-english/ (Tutor de Inglês)"
info "   └─ agents/tutor-iot/     (Tutor de IoT)"
echo ""
info "🚀 Próximos passos:"
info "   1. Configure o .env (especialmente TELEGRAM_BOT_TOKEN)"
info "   2. Substitua openclaw.json pelo openclaw-multiagent.json"
info "   3. Inicie: docker-compose up -d"
info "   4. Monitore: docker-compose logs -f openclaw"
info "   5. Teste via Telegram"
echo ""
info "📚 Documentação completa em: guia-multiagentes-openclaw.md"
echo ""

# ====================================================
# Perguntar se quer iniciar automaticamente
# ====================================================
read -p "Deseja iniciar o OpenClaw agora? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    log "🚀 Iniciando OpenClaw..."
    
    # Backup do openclaw.json original se existir
    if [ -f "${DATA_DIR}/openclaw.json" ]; then
        mv "${DATA_DIR}/openclaw.json" "${DATA_DIR}/openclaw.json.old"
    fi
    
    # Copiar nova configuração
    if [ -f "${PROJECT_ROOT}/openclaw-multiagent.json" ]; then
        cp "${PROJECT_ROOT}/openclaw-multiagent.json" "${DATA_DIR}/openclaw.json"
        log "✅ Configuração multiagente aplicada"
    fi
    
    # Iniciar containers
    cd "$PROJECT_ROOT"
    docker-compose up -d
    
    log "✅ OpenClaw iniciado!"
    info "📊 Monitore os logs com: docker-compose logs -f openclaw"
else
    info "👍 Ok! Inicie manualmente com: docker-compose up -d"
fi

echo ""
log "🎉 Tudo pronto! Bom uso dos multiagentes!"
