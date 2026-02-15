# 🚀 Quick Start - OpenClaw + Ollama

## ✅ O que já está pronto:

- ✅ 4 containers rodando (ollama, openclaw, nginx, open-webui)
- ✅ Nginx roteando requisições corretamente
- ✅ OpenClaw Gateway escutando em `ws://localhost:18789`
- ✅ APIs communicando entre containers
- ✅ Variáveis de ambiente configuradas (Gemini + OpenRouter)

---

## 📥 Passo 1: Baixar Modelos Ollama

```powershell
# Puxar modelo padrão
docker exec ollama ollama pull llama2

# Opcional: Puxar modelos adicionais
docker exec ollama ollama pull mistral
docker exec ollama ollama pull neural-chat
docker exec ollama ollama pull dolphin-mixtral

# Listar modelos baixados
docker exec ollama ollama list
```

**Tempo esperado:** 5-15 minutos (depende do modelo e velocidade da internet)

Exemplo de saída esperada:
```
NAME                    ID              SIZE      MODIFIED
llama2:latest           3fd1a6efb50b    3.8 GB    2 minutes ago
mistral:latest          42182419e3f1    4.1 GB    1 minute ago
```

---

## 🌐 Passo 2: Acessar OpenClaw Dashboard

### Opção A: Via Browser (Recomendado)
1. Abra: **`http://localhost`** no seu navegador
2. Veja o OpenClaw Control UI
3. Se pedir token, ignore (modo `--allow-unconfigured` ativo)

### Opção B: Via Porta Direta
1. Abra: **`http://localhost:18790`** (rota via nginx)
2. Ou: **`http://localhost:18789`** (porta direta do gateway)

### Opção C: Autenticação com Token (Segurança)

⚠️ **Importante:** O OpenClaw está rodando em modo `--allow-unconfigured`, logo **NÃO PRECISA de token para funcionar**. 

Se quiser **adicionar autenticação segura**, há 3 formas:

#### Forma 1: Token Simples (Recomendado)

**Step 1: Gerar um token (qualquer string segura):**

```powershell
# Opção A: UUID aleatório (melhor)
[guid]::NewGuid().ToString()
# Saída exemplo: 550e8400-e29b-41d4-a716-446655440000

# Opção B: String alfanumérica simples
$token = -join ((97..122) + (65..90) + (48..57) | Get-Random -Count 32 | %{[char]$_})
$token
# Saída exemplo: mNpQrStUvwXyZaBcDeFgHiJkLmNoPqRs
```

**Step 2: Parar o container OpenClaw:**
```powershell
docker stop openclaw
```

**Step 3: Editar `entrypoint.sh` para incluir token:**

Encontre a linha do `openclaw gateway` e mude:
```bash
# De (ATUAL):
openclaw gateway --port 18789 --allow-unconfigured

# Para (NOVO):
openclaw gateway --port 18789 --token "seu_token_aqui"
```

Ou use variável de ambiente no docker-compose:
```yaml
entrypoint: sh -c 'openclaw gateway --port 18789 --token "${OPENCLAW_TOKEN}" --allow-unconfigured'
environment:
  - OPENCLAW_TOKEN=seu_token_muito_secreto_aqui
```

**Step 4: Reiniciar:**
```powershell
docker-compose -f docker-compose-integrated.yml up -d --build
```

**Step 5: Acessar com token:**
```
http://localhost/?token=seu_token_aqui
```

Se token correto, conecta normalmente.  
Se token faltoso ou incorreto, vê erro: `unauthorized: gateway token mismatch`

---

#### Forma 2: Usar .env (Mais Limpo)

**Step 1: Editar `.env` na raiz:**
```bash
# .env
OPENCLAW_TOKEN=seu_token_secreto_bem_longo_aqui
OPENCLAW_MODE=token  # ou 'password'
```

**Step 2: No `docker-compose-integrated.yml`, usar variável:**
```yaml
openclaw:
  environment:
    - OPENCLAW_TOKEN=${OPENCLAW_TOKEN}
  entrypoint: sh -c 'openclaw gateway --port 18789 --token "${OPENCLAW_TOKEN}"'
```

**Step 3: Reiniciar:**
```powershell
docker-compose -f docker-compose-integrated.yml up -d --build
```

OpenClaw pega token de `.env` automaticamente.

---

#### Forma 3: Autenticação por Password

Se preferir **senha** ao invés de token:

**Step 1: Editar `entrypoint.sh`:**
```bash
# De:
openclaw gateway --port 18789 --allow-unconfigured

# Para:
openclaw gateway --port 18789 --auth password --password "MinhaSenh@123"
```

**Step 2: Sem editar, via docker run:**
```powershell
docker stop openclaw
docker-compose -f docker-compose-integrated.yml up -d --build
```

**Step 3: Ao acessar browser:**
- Pede senha na primeira vez
- Depois salva em cookies
- Muito mais user-friendly que token

---

### 📋 Resumo: Qual Sistema Usar?

| Modo | Comando | Uso | Segurança |
|------|---------|-----|-----------|
| **Sem Auth (ATUAL)** | `--allow-unconfigured` | Teste/dev local | ❌ Nenhuma |
| **Token** | `--token "uuid_aqui"` | Produção / URLs públicas | ⭐⭐⭐ Alta |
| **Password** | `--auth password --password "pwd"` | Produção / acesso compartilhado | ⭐⭐⭐ Alta |

---

### ✅ Verificar se Token Está Funcionando

```powershell
# Ver logs do OpenClaw
docker-compose logs openclaw | Select-String "token|auth|listen"

# Esperado (com token):
# openclaw | [gateway] token authentication enabled
# openclaw | [gateway] listening on ws://127.0.0.1:18789

# Esperado (sem token):
# openclaw | [gateway] listening on ws://127.0.0.1:18789
```

Teste tentando acessar sem token:
```
GET http://localhost/ (sem ?token=...)
# Resultado: Erro "unauthorized: gateway token mismatch"
```

Teste com token correto:
```
GET http://localhost/?token=seu_token_aqui
# Resultado: Dashboard carrega normalmente
```

---

### 🎯 Recomendação Final

**Para AGORA (teste):** Deixe como está (`--allow-unconfigured` - sem token)

**Para PRODUÇÃO:** Use **Forma 2 (Token via .env)**
- Mais seguro
- Mais fácil de gerenciar
- Sem modificar código

**Comando rápido:**
```powershell
# 1. Gerar token
[guid]::NewGuid().ToString()

# 2. Colar em .env
OPENCLAW_TOKEN=<seu_uuid_aqui>

# 3. Editar entrypoint.sh ou docker-compose
# Usar: --token "${OPENCLAW_TOKEN}"

# 4. Restart
docker-compose up -d --build
```

---

## 📡 Passo 3: Testar Conectividade OpenClaw ↔ Ollama

### Via Container
```powershell
# Testar Ollama API de dentro de OpenClaw
docker exec openclaw sh -c "wget -q -O- http://ollama:11434/api/tags | head -50"

# Ou via Nginx proxy
docker exec openclaw sh -c "wget -q -O- http://localhost/api/ollama/tags | head -50"
```

### Resposta esperada (JSON):
```json
{
  "models": [
    {
      "name": "llama2:latest",
      "modified_at": "2026-02-10T20:58:00.000000Z",
      "size": 3865470976
    }
  ]
}
```

---

## 🎯 Passo 4: Configurar Ollama no OpenClaw

1. **Acesse OpenClaw Dashboard** (http://localhost)
2. **Vá para Settings → AI Providers**
3. **Procure por "Ollama"**
4. **Configure:**
   - **Server URL:** `http://ollama:11434` (ou `http://localhost:11434`)
   - **Model:** `llama2` (ou outro model que puxou)
   - **Enable:** Toggle ON

5. **Salve e teste!**

Exemplo de configuração esperada:
```yaml
ollama:
  enabled: true
  server_url: "http://ollama:11434"
  model: "llama2"
  temperature: 0.7
  top_k: 40
  top_p: 0.9
```

---

## 🎬 Passo 5: Usar OpenClaw

Depois de configurar Ollama:

1. **Na aba "Chat":**
   - Selecione o modelo Ollama
   - Comece uma conversa
   - OpenClaw enviará query para Ollama

2. **Na aba "Control Panel":**
   - Veja o histórico de requisições
   - Monitore performance
   - Veja logs em tempo real

3. **Dicas:**
   - Primeira resposta é lenta (modelo carregando em memória)
   - Use `--allow-unconfigured` para teste rápido
   - Veja logs com: `docker-compose logs -f openclaw`

---

## 🛠️ Troubleshooting

### OpenClaw não conecta em Ollama

**Verificar:**
```powershell
# Dentro do container OpenClaw
docker exec openclaw sh -c "wget -q -O- http://ollama:11434/api/tags"

# Esperado: JSON com lista de modelos
# Se falhar: Ollama container pode não estar rodando
docker ps | grep ollama
```

### Ollama não respondendo

**Verificar:**
```powershell
# Verificar logs do Ollama
docker-compose -f docker-compose-integrated.yml logs ollama | tail -50

# Ver se listening
docker exec ollama sh -c "netstat -tlnp 2>/dev/null | grep 11434"

# Esperado: tcp ... 0.0.0.0:11434 LISTEN
```

### Nginx erro 502 Bad Gateway

**Verificar:**
```powershell
# Ver logs nginx
docker-compose logs nginx

# Esperado: Nenhum erro "upstream"
# Common causes:
# - OpenClaw container não iniciado
# - Porta 18789 não respondendo
```

### Token mismatch no OpenClaw

**Solução:**
```powershell
# Usar --allow-unconfigured (já em uso)
# Ou gerar token explícito

docker stop openclaw
docker exec openclaw openclaw gateway --allow-unconfigured

# Se quiser token seguro:
docker exec openclaw openclaw gateway --token "meu_token_secreto"
```

---

## 📊 Monitorar Sistema

```powershell
# Ver status de todos os containers em tempo real
docker stats

# Ver logs em tempo real de todos os serviços
docker-compose -f docker-compose-integrated.yml logs -f

# Ver logs de um serviço específico
docker-compose -f docker-compose-integrated.yml logs -f openclaw
docker-compose -f docker-compose-integrated.yml logs -f ollama
docker-compose -f docker-compose-integrated.yml logs -f nginx

# Entrar em um container
docker exec -it openclaw bash
docker exec -it ollama sh
```

---

## 🔒 Segurança (Produção)

Para **produção**, recomendado:

1. **Autenticação:**
   ```bash
   openclaw gateway --token "seu_token_muito_secreto_aqui"
   ```

2. **HTTPS/SSL:**
   - Configurar certificados em `nginx/ssl/`
   - Descomente `server { listen 443 ssl; ... }` em nginx.conf

3. **Firewall:**
   - Expor apenas porta 80/443 (Nginx)
   - Manter 11434, 18789 internos apenas

4. **Limites de Recursos:**
   ```yaml
   services:
     ollama:
       deploy:
         resources:
           limits:
             cpus: '4'
             memory: 8G
   ```

---

## ✉️ Próximas Ações Recomendadas

- [ ] Puxar modelos Ollama (`ollama pull llama2`)
- [ ] Acessar OpenClaw dashboard (http://localhost)
- [ ] Testar conectividade OpenClaw → Ollama
- [ ] Configurar Ollama em OpenClaw Settings
- [ ] Fazer primeiro chat com modelo Ollama
- [ ] Revisar logs: `docker-compose logs -f`

---

## 📞 Referência Rápida

| Componente | URL | Porta |
|-----------|-----|-------|
| OpenClaw Dashboard | http://localhost | 80 |
| OpenClaw Direct | http://localhost:18790 | 18790 |
| Ollama API | http://localhost:11434 | 11434 |
| Open-WebUI | http://localhost:3000 | 3000 |
| Nginx Proxy | localhost | 80/443 |

---

*Generated: 2026-02-10*
