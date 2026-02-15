# 🦞 OpenClaw + Ollama - Plano de Integração Completo

## 🔍 O que Descobri Sobre OpenClaw

### Configuração do OpenClaw
OpenClaw **NÃO usa YAML tradicional** para configuração de modelos. Usa:
- **CLI Commands**: `openclaw config set`, `openclaw config add-model`
- **Arquivo Principal**: `~/.openclaw/openclaw.json` (gerado automaticamente)
- **Variáveis de Ambiente**: `GEMINI_API_KEY`, `OPENROUTER_API_KEY`, etc.
- **Onboarding Wizard**: `openclaw onboard` (recomendado)

### Provedores Suportados
```
✅ Google Gemini (gemini-2.5-flash)
✅ OpenAI (GPT-4, etc)
✅ Anthropic (Claude - recomendado!)
✅ OpenRouter (proxy de múltiplos modelos)
✅ Local (via ferramentas HTTP/curl)
```

### Gateway
- **Porta padrão**: 18789
- **Protocolo**: WebSocket
- **Autenticação**: Token gerado com `openclaw doctor --generate-gateway-token`
- **Dashboard**: http://localhost:18789/?token=<TOKEN>

---

## 🔌 3 Opções de Integração com Ollama

### **OPÇÃO 1: Direto via API HTTP (Recomendado - Simples)**

**Como funciona:**
- OpenClaw acessa Ollama via REST API
- Sem modificar arquivos de config
- OpenClaw pode chamar Ollama como uma ferramenta externa

**Vantagens:**
- Mais simples
- Não precisa modificar OpenClaw
- Funciona com redes separadas

**Implementação:**

1. **Deixe Ollama rodando:**
```bash
docker run -d --name ollama -p 11434:11434 ollama/ollama
docker exec ollama ollama pull llama2
```

2. **No Docker Compose, adicione a variável:**
```yaml
openclaw:
  environment:
    OLLAMA_API_URL: http://ollama:11434
```

3. **OpenClaw pode chamar via skill/comando:**
```bash
# Dentro do OpenClaw (CLI ou Telegram)
/run "curl http://ollama:11434/api/generate -d '{\"model\":\"llama2\",\"prompt\":\"Hello\"}'"
```

---

### **OPÇÃO 2: Via Provider Customizado (Ideal - Mais Integrado)**

Se OpenClaw tiver suporte a providers HTTP genéricos, configure:

```bash
# Dentro do container OpenClaw
docker exec openclaw bash -c '
openclaw config set agent.model "ollama/llama2"
openclaw config set models.ollama.api_url "http://ollama:11434"
openclaw config set models.ollama.enabled true
'
```

**Problema:** Precisa validar se OpenClaw suporta isso nativamente.

---

### **OPÇÃO 3: Plugin/Skill Customizado (Avançado)**

Crie um skill que integra Ollama com OpenClaw:

```javascript
// skill: /ollama-bridge/ollama.ts
async function generateWithOllama(prompt: string, model: string = "llama2") {
  const response = await fetch('http://ollama:11434/api/generate', {
    method: 'POST',
    body: JSON.stringify({ model, prompt })
  });
  return response.json();
}
```

---

## 🎯 Implementação Recomendada (Opção 1 + Docker Compose Unificado)

### Passo 1: Atualizar docker-compose-integrated.yml

```yaml
version: '3.8'

services:
  # Ollama - LLM Local
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    networks:
      - openclaw-net
    volumes:
      - ollama_data:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0:11434
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 3

  # OpenClaw
  openclaw:
    build: .
    container_name: openclaw
    user: "1000:1000"
    restart: unless-stopped
    network_mode: "service:nginx"
    environment:
      - GEMINI_API_KEY=${GEMINI_API_KEY}
      - OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
      - GEMINI_MODEL=gemini-2.5-flash
      - LOG_LEVEL=INFO
      - TZ=America/Sao_Paulo
      - OPENCLAW_HOME=/home/openclaw/.config/openclaw
      # 🆕 Variáveis para Ollama
      - OLLAMA_API_URL=http://ollama:11434
      - OLLAMA_MODEL=llama2
    volumes:
      - ./data:/home/openclaw/.config/openclaw
      - ./logs:/home/openclaw/logs
      - ./config/custom-config.yaml:/home/openclaw/.config/openclaw/custom-config.yaml:ro
    depends_on:
      - nginx
      - ollama

  # Nginx Proxy
  nginx:
    image: nginx:alpine
    container_name: openclaw-proxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "18790:18789"
      - "443:443"
      - "11434:11434"  # Expõe Ollama API
      - "3000:3000"    # Open-WebUI
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    networks:
      - openclaw-net
    depends_on:
      - ollama

  # Open-WebUI (opcional)
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: unless-stopped
    networks:
      - openclaw-net
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
    volumes:
      - open_webui_data:/app/backend/data
    depends_on:
      - ollama

volumes:
  ollama_data:
  open_webui_data:

networks:
  openclaw-net:
    driver: bridge
```

### Passo 2: Comandos Iniciais

```bash
# 1. Pull do modelo
docker exec ollama ollama pull llama2
docker exec ollama ollama pull mistral

# 2. Verificar disponibilidade
docker exec ollama ollama list

# 3. Test Ollama diretamente
curl http://localhost:11434/api/tags
```

### Passo 3: Configurar OpenClaw (Depois do container rodar)

```bash
# Acessar container
docker exec -it openclaw bash

# Configurar (opcional, pois tem OLLAMA_API_URL já)
openclaw config set models.ollama.enabled true

# Ver status
openclaw config get | grep ollama

# Iniciaste o gateway
openclaw gateway --port 18789
```

---

## 📊 Comparação das Opções

| Aspecto | Opção 1 (HTTP) | Opção 2 (Provider) | Opção 3 (Skill) |
|---------|---|---|---|
| **Complexidade** | ⭐ Simples | ⭐⭐ Média | ⭐⭐⭐ Complexa |
| **Setup** | 5 min | 15 min | 30+ min |
| **Redes Separadas** | ✅ Sim | ❓ Talvez | ✅ Sim |
| **Native Integration** | ❌ Manual | ✅ Sim | ✅ Sim |
| **Fallback** | ❌ Não | ✅ Sim | ✅ Sim |
| **Recomendada** | ✅ **SIM** | ⚠️ Se suportado | ⚠️ Avançado |

---

## 🚀 Quick Start (Opção 1)

```bash
# 1. Copie o docker-compose-integrated.yml
cp docker-compose-integrated.yml docker-compose.yml

# 2. Inicie tudo
docker-compose up -d --build

# 3. Aguarde 30s e faça pull dos modelos
sleep 30
docker exec ollama ollama pull llama2

# 4. Verifique status
docker-compose ps
docker logs openclaw
docker logs ollama

# 5. Teste Ollama
curl http://localhost:11434/api/tags

# 6. Acesse OpenClaw Dashboard
# Gere token:
docker exec openclaw openclaw doctor --generate-gateway-token
# Acesse: http://localhost/?token=<TOKEN>
```

---

## 🧪 Testes de Integração

### 1. Verificar Conectividade Ollama ↔ OpenClaw
```bash
docker exec openclaw curl -v http://ollama:11434/api/tags
```

Esperado: JSON com lista de modelos

### 2. Testar Geração de Texto
```bash
curl http://localhost:11434/api/generate \
  -d '{"model":"llama2","prompt":"Hello, how are you?","stream":false}'
```

### 3. Verificar Logs
```bash
docker logs openclaw -f
docker logs ollama -f
docker logs openclaw-proxy -f
```

---

## 🔧 Troubleshooting

### OpenClaw não consegue acessar Ollama
```bash
# Solution 1: Verifique conectividade
docker exec openclaw ping ollama

# Solution 2: Verifique firewall interno
docker inspect openclaw-net

# Solution 3: Reinicie networks
docker-compose down
docker-compose up -d
```

### Ollama lento ou fora de memória
```bash
# Verifique recursos
docker stats ollama

# Use modelo quantizado (menor)
docker exec ollama ollama pull neural-chat:7b-v3-q4_K_M

# Limpe cache
docker exec ollama ollama pull --clean
```

### OpenClaw não encontra variáveis
```bash
# Verifique env vars
docker exec openclaw env | grep OLLAMA

# Force uma reescrita do config
docker exec openclaw openclaw config set OLLAMA_API_URL http://ollama:11434
```

---

## 📝 Checklist Final

- [ ] docker-compose-integrated.yml revisado
- [ ] Ollama image pulled e testado
- [ ] Modelos baixados (pull llama2, mistral, etc)
- [ ] Networks Docker configuradas
- [ ] Variáveis OLLAMA_API_URL setadas
- [ ] OpenClaw inicia sem erros
- [ ] Teste `curl http://localhost:11434/api/tags` funciona
- [ ] Dashboard OpenClaw acessível e com token
- [ ] Documentação de modelos atualizada
- [ ] Performance monitorada (docker stats)

---

## 📚 Próximos Passos

1. **Confirme** qual Opção você quer usar (recomendo Opção 1)
2. **Defina** quais modelos Ollama serão usados
3. **Teste** a integração com curl antes de usar via OpenClaw
4. **Configure** HTTPS se necessário
5. **Documumente** os comandos de manutenção

---

## 🌐 Acesso aos Serviços

| Serviço | URL | Notas |
|---------|-----|-------|
| **OpenClaw** | http://localhost | Via Nginx |
| **OpenClaw Dashboard** | http://localhost/?token=xxx | Requer token |
| **Ollama API** | http://localhost:11434 | REST API |
| **Open-WebUI** | http://localhost:3000 | Interface Webui |
| **OpenClaw Direto** | http://localhost:18790 | Bypass Nginx |

