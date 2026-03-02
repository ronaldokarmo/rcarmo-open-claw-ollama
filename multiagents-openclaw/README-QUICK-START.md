# 🚀 Quick Start - Multiagentes OpenClaw

## 📦 O que você recebeu

```
📁 Arquivos de Configuração:
├── guia-multiagentes-openclaw.md      # Guia completo e detalhado
├── openclaw-multiagent.json           # Configuração dos agentes
├── docker-compose-multiagent.yml      # Docker Compose atualizado
├── quick-setup-multiagent.sh          # Script de setup automático
└── README-QUICK-START.md              # Este arquivo
```

---

## ⚡ Setup Rápido (5 minutos)

### 1️⃣ Preparar ambiente

```bash
# Navegue até o diretório do projeto
cd openclaw-docker

# Torne o script executável
chmod +x quick-setup-multiagent.sh

# Execute o setup automático
./quick-setup-multiagent.sh
```

O script vai:
- ✅ Criar estrutura de diretórios
- ✅ Gerar system prompts
- ✅ Configurar knowledge base
- ✅ Ajustar permissões

### 2️⃣ Configurar variáveis de ambiente

Edite `.env`:

```bash
nano .env
```

**Mínimo necessário:**
```env
TELEGRAM_BOT_TOKEN=seu_token_aqui
OLLAMA_API_BASE=http://ollama:11434
OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
```

### 3️⃣ Aplicar configuração multiagente

```bash
# Backup da config atual
cp data/.openclaw/openclaw.json data/.openclaw/openclaw.json.backup

# Aplicar nova configuração
cp openclaw-multiagent.json data/.openclaw/openclaw.json
```

### 4️⃣ Iniciar containers

```bash
# Usar o docker-compose atualizado (opcional)
cp docker-compose-multiagent.yml docker-compose.yml

# Iniciar
docker-compose up -d

# Monitorar logs
docker-compose logs -f openclaw
```

### 5️⃣ Testar

**Via Telegram:**
```
/start
Olá! Como posso ajudar?

> Preciso de ajuda com o present perfect
[Tutor English responde]

> Como conectar sensor DHT22 no ESP32?
[Tutor IoT responde]
```

**Menção direta:**
```
@tutor-english: How do I use "has been" vs "have been"?
@tutor-iot: Show me ESP32 I2C pinout
```

---

## 🏗️ Estrutura Criada

```
data/.openclaw/
├── agents/
│   ├── main/
│   │   ├── agent/
│   │   │   ├── system.md          # Prompt do coordenador
│   │   │   ├── agent.json         # Metadados
│   │   │   └── knowledge/         # Base de conhecimento
│   │   └── logs/
│   ├── tutor-english/
│   │   ├── agent/
│   │   │   ├── system.md          # Prompt especializado
│   │   │   ├── knowledge/
│   │   │   │   ├── grammar-rules.md
│   │   │   │   └── vocabulary-exercises.md
│   │   │   └── tools/
│   │   └── logs/
│   └── tutor-iot/
│       ├── agent/
│       │   ├── system.md
│       │   ├── knowledge/
│       │   │   ├── esp32-pinout.md
│       │   │   ├── arduino-ref.md
│       │   │   └── sensor-database.json
│       │   └── tools/
│       └── logs/
├── workspace/                      # Main agent
├── workspace-tutor-english/        # English tutor
└── workspace-tutor-iot/            # IoT tutor
```

---

## 🎯 Como os Agentes Funcionam

### Fluxo de Mensagem

```
Usuário: "How do I use present perfect?"
    ↓
Main Agent analisa keywords: "present perfect" → inglês
    ↓
Delega para tutor-english
    ↓
Tutor English processa e responde
    ↓
Main Agent consolida resposta
    ↓
Usuário recebe resposta
```

### Roteamento Automático

**Tutor English** é acionado para:
- Palavras-chave: english, inglês, grammar, vocabulary, translate
- Padrões: "how do you say", "corrija", "in english"

**Tutor IoT** é acionado para:
- Palavras-chave: arduino, esp32, sensor, circuit, mqtt, i2c
- Padrões: pinMode, digitalWrite, nomes de sensores

**Main** responde diretamente:
- Conversas gerais
- Saudações
- Perguntas não especializadas

---

## 🛠️ Customização

### Adicionar novo agente

```bash
# Criar estrutura
mkdir -p data/.openclaw/agents/meu-agente/agent/{knowledge,tools,logs}
mkdir -p data/.openclaw/workspace-meu-agente

# Criar system prompt
nano data/.openclaw/agents/meu-agente/agent/system.md

# Adicionar ao openclaw.json
{
  "id": "meu-agente",
  "name": "Meu Agente",
  "role": "specialist",
  "keywords": ["palavra1", "palavra2"],
  ...
}

# Reiniciar
docker-compose restart openclaw
```

### Modificar system prompts

```bash
# Editar prompt do tutor de inglês
nano data/.openclaw/agents/tutor-english/agent/system.md

# O OpenClaw recarrega automaticamente (autoReload: true)
# Ou force restart:
docker-compose restart openclaw
```

### Adicionar conhecimento

```bash
# Adicionar novo arquivo de conhecimento
echo "# Novo Conhecimento" > data/.openclaw/agents/tutor-iot/agent/knowledge/novo-topico.md

# Atualizar índice
cd data/.openclaw/agents/tutor-iot/agent/knowledge/
ls -1 *.md > index.txt
```

---

## 📊 Monitoramento

### Logs em tempo real

```bash
# Todos os containers
docker-compose logs -f

# Apenas OpenClaw
docker-compose logs -f openclaw

# Apenas Ollama
docker-compose logs -f ollama
```

### Status dos agentes

```bash
# Script de monitoramento (criar monitor.sh)
./scripts/monitor-agents.sh
```

### Health checks

```bash
# Gateway
curl http://localhost:18790/

# Ollama
curl http://localhost:11434/api/tags

# Telegram bot
curl https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe
```

---

## 🐛 Troubleshooting Rápido

### Agente não responde
```bash
# Verificar se está rodando
docker ps

# Ver logs
docker-compose logs openclaw | tail -50

# Reiniciar
docker-compose restart openclaw
```

### Roteamento errado
```bash
# Verificar keywords
cat data/.openclaw/openclaw.json | jq '.agents.list[].keywords'

# Adicionar mais keywords se necessário
# Editar openclaw.json → adicionar keyword → reiniciar
```

### Ollama lento
```bash
# Reduzir contexto
# docker-compose.yml:
OLLAMA_CONTEXT_LENGTH=4096  # ao invés de 8192

# Limitar memória
OLLAMA_MAX_LOADED_MODELS=1
```

### Espaço em disco
```bash
# Limpar logs antigos
find data/.openclaw/agents/*/logs -name "*.log" -mtime +7 -delete

# Limpar workspaces temporários
rm -rf data/.openclaw/workspace-*/tmp/*
```

---

## 📚 Documentação Completa

Para informações detalhadas, consulte:

- **Guia Completo**: `guia-multiagentes-openclaw.md`
- **OpenClaw Docs**: https://docs.openclaw.com
- **Telegram Bot API**: https://core.telegram.org/bots/api

---

## 🆘 Comandos Úteis

```bash
# Parar tudo
docker-compose down

# Parar e remover volumes (CUIDADO!)
docker-compose down -v

# Rebuild da imagem
docker-compose build --no-cache openclaw

# Acessar container
docker exec -it openclaw bash

# Ver uso de recursos
docker stats

# Backup completo
tar -czf openclaw-backup-$(date +%Y%m%d).tar.gz data/ .env

# Restaurar backup
tar -xzf openclaw-backup-YYYYMMDD.tar.gz
```

---

## ✨ Próximos Passos

1. ✅ **Testar cada agente individualmente**
2. ✅ **Adicionar mais conhecimento às bases**
3. ✅ **Customizar system prompts para seu uso**
4. ✅ **Implementar ferramentas customizadas (opcional)**
5. ✅ **Configurar monitoramento (opcional)**

---

## 🎉 Pronto!

Seus multiagentes estão configurados e prontos para uso!

**Principais features:**
- ✅ Roteamento automático baseado em keywords
- ✅ Workspaces isolados por agente
- ✅ Knowledge base dedicada
- ✅ System prompts especializados
- ✅ Integração com Telegram

**Teste agora:**
```
Telegram → /start
> Preciso de ajuda com o present perfect em inglês
> Como conectar um sensor DHT22 no ESP32?
```

---

*Setup criado em: 2026-02-28*  
*Versão: 1.0*
