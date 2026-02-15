# 🚀 Configuração Multi-Provider OpenClaw

## 📋 Resumo da Configuração

Seu OpenClaw agora está configurado para usar **3 providers simultaneamente**:

1. **OpenRouter** - Melhor custo/desempenho com múltiplos modelos
2. **Gemini** - Modelos Google rápidos e eficientes  
3. **Ollama** - Modelos locais sem custo de API

---

## 🔑 Variáveis de Ambiente (`.env`)

Verifique que seu `.env` contém:

```env
# OpenRouter (recomendado como padrão)
OPENROUTER_API_KEY=sk-or-v1-...

# Gemini
GEMINI_API_KEY=AIzaSy...

# Anthropic (opcional)
ANTHROPIC_API_KEY=sk-ant-...

# OpenAI (opcional)
OPENAI_API_KEY=sk-proj-...
```

---

## ⚙️ Arquivos Modificados

### 1. **`config/custom-config.yaml`**
- Define o modelo padrão como `openrouter/auto`
- Lista todos os modelos disponíveis
- Configura Ollama para rodar localmente

### 2. **`docker-compose.yml`**
- Passa todas as API keys como variáveis de ambiente
- Configura URL do Ollama (`http://ollama:11434`)

### 3. **`entrypoint.sh`**
- Removeu onboarding interativo (causa reinicializações)
- Cria auth profiles automaticamente
- Exibe quais providers estão disponíveis

---

## 🧪 Testando a Configuração

### Passo 1: Limpar e Reconstruir

```bash
docker compose down -v
docker compose build --no-cache
```

### Passo 2: Iniciar o Stack

```bash
docker compose up
```

Você deve ver:

```
🎯 Iniciando Gateway na porta 18789...
   Disponível em: http://127.0.0.1:18789
   - OpenRouter: openrouter/auto
   - Gemini: google/gemini-2.0-flash
   - Ollama Local: ollama/llama2
```

### Passo 3: Acessar o Gateway

**Via Nginx (porta 80):**
```
http://localhost
```

**Via Gateway direto (porta 18790):**
```
http://localhost:18790
```

---

## 🛠️ Usando os Modelos

### OpenRouter (Padrão)

```bash
# Usar modelo automático (melhor custo/performance)
curl -X POST http://localhost:18790/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openrouter/auto",
    "messages": [{"role": "user", "content": "Olá!"}]
  }'
```

### Gemini

```bash
curl -X POST http://localhost:18790/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google/gemini-2.0-flash",
    "messages": [{"role": "user", "content": "Olá!"}]
  }'
```

### Ollama (Local)

Primeiro, certifique-se que um modelo está disponível:

```bash
docker exec ollama ollama pull llama2
# ou
docker exec ollama ollama pull mistral
```

Depois use:

```bash
curl -X POST http://localhost:18790/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "ollama/llama2",
    "messages": [{"role": "user", "content": "Olá!"}]
  }'
```

---

## 📊 Logs e Diagnóstico

### Ver logs do OpenClaw

```bash
docker compose logs -f openclaw
```

### Ver logs do Ollama

```bash
docker compose logs -f ollama
```

### Verificar status do Ollama

```bash
docker exec ollama ollama list
```

### Acessar o Open-WebUI (interface Ollama)

```
http://localhost:3000
```

---

## ⚡ Troubleshooting

### Problema: "No API key found"

**Solução:** Verifique que todas as variáveis estão no `.env`:

```bash
# Windows PowerShell
get-content .env

# Linux/Mac
cat .env
```

### Problema: Gateway reiniciando continuamente

**Solução:** O arquivo `custom-config.yaml` não deve estar sendo modificado. Certifique-se que:

1. O arquivo está no caminho correto: `config/custom-config.yaml`
2. O arquivo está montado como **read-only** (`:ro`) no docker-compose
3. Nenhum processo está tentando escrever nele

### Problema: Ollama não conecta

**Solução:** Verifique a conectividade:

```bash
# Entre no container do OpenClaw
docker exec -it openclaw bash

# Teste a conexão com Ollama
curl http://ollama:11434/api/tags
```

---

## 🎯 Modelos Recomendados

### Para Tarefas Gerais (OpenRouter)
```
openrouter/auto  - Automático (melhor custo)
openrouter/anthropic/claude-opus-4  - Claude Opus (melhor qualidade)
```

### Para Respostas Rápidas (Gemini)
```
google/gemini-2.0-flash  - Muito rápido e eficiente
```

### Para Local/Privado (Ollama)
```
ollama/llama2  - Bom equilíbrio
ollama/mistral  - Rápido
ollama/neural-chat  - Conversacional
```

---

## 📝 Próximos Passos

1. ✅ Teste a configuração com cada provider
2. ✅ Configure canais (Telegram, Discord, etc) em `custom-config.yaml`
3. ✅ Personalize plugins em `agents.defaults.plugins`
4. ✅ Configure auth profiles específicos se necessário

---

## 📚 Referências

- [OpenClaw Documentation](https://openclaw.ai)
- [OpenRouter Modelos](https://openrouter.ai/models)
- [Ollama Modelos](https://ollama.ai/library)
