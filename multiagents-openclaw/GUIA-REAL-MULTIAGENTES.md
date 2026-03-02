# 🎯 Guia REAL de Multiagentes - OpenClaw 2026.2.26

## ✅ A Verdade Sobre Multiagentes no OpenClaw Atual

Após sua experiência com `openclaw doctor --fix`, ficou claro:

### ❌ O Que NÃO Funciona (Rejeitado pelo doctor)
- `workspace` - Campo não reconhecido
- `agentDir` - Campo não reconhecido  
- `systemPrompt` - Campo não reconhecido (inline)
- `description` - Campo não reconhecido
- `enabled` - Campo não reconhecido
- `routing-engine` - Plugin não existe
- `trackRouting` - Feature não existe
- `trackPerformance` - Feature não existe

### ✅ O Que FUNCIONA (Aceito pelo doctor)
- `id` - Identificador do agente
- `name` - Nome do agente
- `model` - Modelo a usar

**Conclusão:** A versão atual do OpenClaw tem suporte **básico** para múltiplos agentes, mas não tem as features avançadas de roteamento automático e system prompts inline.

---

## 🔧 Como Implementar Multiagentes REALMENTE

### Método 1: System Prompts em Arquivos (RECOMENDADO)

O OpenClaw lê automaticamente o arquivo `system.md` de cada agente.

**Estrutura necessária:**
```
data/.openclaw/
├── agents/
│   ├── main/
│   │   └── agent/
│   │       └── system.md  ← OpenClaw lê daqui
│   ├── tutor-english/
│   │   └── agent/
│   │       └── system.md  ← OpenClaw lê daqui
│   └── tutor-iot/
│       └── agent/
│           └── system.md  ← OpenClaw lê daqui
└── openclaw.json
```

**openclaw.json (mínimo necessário):**
```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "name": "Assistente Geral",
        "model": "ollama/qwen2.5:1.5b"
      },
      {
        "id": "tutor-english",
        "name": "Professor de Inglês",
        "model": "ollama/smollm2:1.7b"
      },
      {
        "id": "tutor-iot",
        "name": "Engenheiro IoT",
        "model": "ollama/phi3.5"
      }
    ]
  }
}
```

---

## 📁 Setup Completo Passo a Passo

### Passo 1: Criar Estrutura de Diretórios

```bash
cd openclaw-docker

# Criar diretórios para cada agente
mkdir -p data/.openclaw/agents/main/agent
mkdir -p data/.openclaw/agents/tutor-english/agent
mkdir -p data/.openclaw/agents/tutor-iot/agent

# Corrigir permissões
sudo chown -R 1000:1000 data/.openclaw/agents/
```

### Passo 2: Instalar System Prompts

```bash
# Copiar os arquivos de system prompts que criei
cp system-prompts/main-system.md data/.openclaw/agents/main/agent/system.md
cp system-prompts/tutor-english-system.md data/.openclaw/agents/tutor-english/agent/system.md
cp system-prompts/tutor-iot-system.md data/.openclaw/agents/tutor-iot/agent/system.md

# Corrigir permissões
sudo chown 1000:1000 data/.openclaw/agents/*/agent/system.md
sudo chmod 644 data/.openclaw/agents/*/agent/system.md
```

### Passo 3: Aplicar Configuração JSON

```bash
# Backup
cp data/.openclaw/openclaw.json data/.openclaw/openclaw.json.backup

# Aplicar nova config
cp openclaw-real-multiagent.json data/.openclaw/openclaw.json
sudo chown 1000:1000 data/.openclaw/openclaw.json

# Validar
docker exec -it openclaw openclaw doctor --fix
```

**Resultado esperado:**
```
✅ Config validated successfully
```

### Passo 4: Reiniciar

```bash
docker-compose restart openclaw
docker-compose logs -f openclaw
```

---

## 🎮 Como Usar os Multiagentes

### Interface Web (http://localhost:18790)

1. **Trocar de Agente:**
   - Menu superior → Dropdown de agentes
   - Selecione: "Professor de Inglês" ou "Engenheiro IoT"

2. **Conversar:**
   ```
   [Selecionou: Professor de Inglês]
   
   Você: How do I use present perfect?
   
   Bot: 📚 Present Perfect - Passado com Relevância
        O Present Perfect é usado quando...
        [resposta especializada]
   ```

### Telegram

1. **Via Comando /agent:**
   ```
   Você: /agent
   Bot: Selecione um agente:
        • main - Assistente Geral
        • tutor-english - Professor de Inglês
        • tutor-iot - Engenheiro IoT
   
   Você: tutor-english
   Bot: ✅ Agora você está conversando com Professor de Inglês
   
   Você: explain phrasal verbs
   Bot: [resposta especializada]
   ```

2. **Via Menção (se suportado):**
   ```
   Você: @tutor-iot
         Como conectar DHT22 no ESP32?
   
   Bot: [resposta do tutor-iot]
   ```

---

## 🧪 Como Testar

### Teste 1: Verificar System Prompts

```bash
# Ver se arquivos existem e têm conteúdo
ls -la data/.openclaw/agents/*/agent/system.md
cat data/.openclaw/agents/main/agent/system.md | head -20
```

### Teste 2: Validar Configuração

```bash
docker exec -it openclaw openclaw doctor
```

Deve mostrar:
```
✅ Config valid
✅ 3 agents configured
```

### Teste 3: Testar Cada Agente

**Main (Geral):**
```
Pergunta: "Quais agentes você tem disponíveis?"
Resposta esperada: Lista os 3 agentes
```

**Tutor English:**
```
Pergunta: "Explain present perfect"
Resposta esperada: Explicação com emojis 📚 ✅ ❌
```

**Tutor IoT:**
```
Pergunta: "ESP32 pinout for I2C"
Resposta esperada: Diagrama ASCII com emojis 🔌 ⚠️
```

---

## 📊 Limitações da Versão Atual

| Feature | Status | Alternativa |
|---------|--------|-------------|
| Roteamento automático | ❌ Não suportado | Seleção manual |
| System prompt inline | ❌ Não suportado | Arquivo system.md |
| Keywords/triggers | ❌ Não suportado | Sugestão do main |
| Workspaces isolados | ❌ Não configurável | OpenClaw gerencia |
| Múltiplos modelos | ✅ Funciona | Configure por agente |
| Troca de agente | ✅ Funciona | Via interface |

---

## 🎯 Expectativas Realistas

### O Que Você VAI Ter:

✅ **3 agentes funcionais** com comportamentos diferentes
✅ **System prompts personalizados** via system.md
✅ **Modelos diferentes** por agente (1.5B, 1.7B, 3.8B)
✅ **Troca manual** entre agentes na interface
✅ **Contexto mantido** dentro de cada agente

### O Que Você NÃO Vai Ter:

❌ Roteamento automático por keywords
❌ Delegação automática main → especialista
❌ @menções funcionando automaticamente
❌ Routing engine visual

### Como Compensar:

1. **Main agent sugere** qual agente usar
2. **Usuário troca manualmente** na interface
3. **System prompts claros** fazem diferença na qualidade

---

## 🔍 Debugging

### Problema: System prompts não funcionam

**Verificar:**
```bash
# Arquivo existe?
ls -la data/.openclaw/agents/tutor-english/agent/system.md

# Permissões corretas?
stat data/.openclaw/agents/tutor-english/agent/system.md
# Deve ser: 1000:1000 -rw-r--r--

# OpenClaw consegue ler?
docker exec -it openclaw cat /home/openclaw/.openclaw/agents/tutor-english/agent/system.md
```

### Problema: Agente não aparece na interface

**Verificar:**
```bash
# Config válida?
docker exec -it openclaw openclaw doctor

# Agente listado?
docker exec -it openclaw openclaw config get agents.list
```

### Problema: Resposta genérica (ignora system prompt)

**Causa provável:** Modelo muito pequeno não segue instruções complexas

**Soluções:**
1. Simplificar system prompt
2. Usar modelo maior (3B+) se tiver RAM
3. Ajustar temperatura: `"temperature": 0.7`

---

## 💡 Dicas de Otimização

### Para Modelos Pequenos (1-2B):

1. **System prompts curtos e diretos**
   ```markdown
   # Professor de Inglês
   
   Explique gramática em português.
   Use emojis: 📚 regras, ✅ certo, ❌ erro.
   Dê exemplos práticos.
   ```

2. **Evite instruções muito complexas**
   ❌ "Analyze the linguistic structure and provide..."
   ✅ "Explique de forma simples"

3. **Use exemplos no prompt**
   ```markdown
   Exemplo de resposta:
   
   📚 Present Perfect é usado para...
   ✅ I have lived here
   ❌ I have went
   ```

### Para Modelos Maiores (3B+):

Pode usar os prompts completos que criei sem modificação.

---

## 📚 Arquivos Fornecidos

1. **openclaw-real-multiagent.json** - Config mínima funcional
2. **system-prompts/main-system.md** - Prompt do assistente geral
3. **system-prompts/tutor-english-system.md** - Prompt professor inglês
4. **system-prompts/tutor-iot-system.md** - Prompt engenheiro IoT

---

## 🚀 Próximos Passos

1. ✅ Criar estrutura de diretórios
2. ✅ Instalar system prompts
3. ✅ Aplicar configuração
4. ✅ Validar com `doctor`
5. ✅ Reiniciar OpenClaw
6. ✅ Testar cada agente
7. ⚙️ Ajustar prompts conforme necessário

---

## 🎉 Conclusão

Apesar das limitações da versão atual, você PODE ter multiagentes funcionais:
- **3 agentes especializados** ✅
- **Comportamentos distintos** ✅  
- **Modelos otimizados** ✅
- **Troca manual funcional** ✅

A experiência será **manual** (usuário escolhe agente), mas os agentes terão **personalidades e expertise reais** graças aos system prompts detalhados.

---

*Guia criado em: 2026-03-01*  
*Versão: Realista - Baseado em testes reais*  
*OpenClaw: 2026.2.26*
