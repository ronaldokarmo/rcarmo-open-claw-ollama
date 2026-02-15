# 🔐 Token do OpenClaw - Guia Prático

## TL;DR Rápido

Quer token para OpenClaw? **3 passos:**

1. **Gerar token:**
   ```powershell
   [guid]::NewGuid().ToString()
   # Copiar a saída
   ```

2. **Siga um dos métodos abaixo**

3. **Reiniciar e acessar com:**
   ```
   http://localhost/?token=SEU_TOKEN_AQUI
   ```

---

## ❓ O que é Token do OpenClaw?

- É uma string de autenticação (como uma senha)
- Previne acesso não autorizado ao gateway
- Obrigatório quando usar em produção/público
- **Atualmente:** OpenClaw está SEM token (`--allow-unconfigured`), qualquer um acessa

---

## 🚀 MÉTODO 1: Via .env (Mais Simples)

### Passo 1: Gerar token
```powershell
# No PowerShell, rode isso e copie a saída:
[guid]::NewGuid().ToString()

# Exemplo de saída:
# 550e8400-e29b-41d4-a716-446655440000
```

### Passo 2: Editar `.env` na raiz do projeto

```bash
# Antes (.env):
GEMINI_API_KEY=abc123...
OPENROUTER_API_KEY=xyz789...

# Depois (.env):
GEMINI_API_KEY=abc123...
OPENROUTER_API_KEY=xyz789...
OPENCLAW_TOKEN=550e8400-e29b-41d4-a716-446655440000  # <- ADICIONAR ESTA LINHA
```

### Passo 3: Editar `entrypoint.sh`

Encontre esta linha:
```bash
openclaw gateway --port 18789 --allow-unconfigured
```

Mude para:
```bash
openclaw gateway --port 18789 --token "${OPENCLAW_TOKEN}"
```

### Passo 4: Reiniciar docker
```powershell
cd e:\openclaw-docker
docker-compose -f docker-compose-integrated.yml down
docker-compose -f docker-compose-integrated.yml up -d --build
```

### Passo 5: Acessar
```
http://localhost/?token=550e8400-e29b-41d4-a716-446655440000
```

---

## 🔑 MÉTODO 2: Via docker-compose direto (Sem editar .env)

Se não quer mexer em `.env`:

### Editar `docker-compose-integrated.yml`

Encontre a seção `openclaw`:
```yaml
openclaw:
  build: .
  container_name: openclaw
  # ... outras configs ...
  environment:
    - GEMINI_API_KEY=${GEMINI_API_KEY}
    - OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
```

Mude o `ENTRYPOINT`:

```yaml
# De (ATUAL):
entrypoint: |
  sh -c '
  export PATH="$PATH:/root/.nvm/versions/node/v20.8.0/bin"
  openclaw onboarding 2>/dev/null || true
  mkdir -p /home/openclaw/.openclaw /home/openclaw/logs /home/openclaw/.config/openclaw
  openclaw gateway --port 18789 --allow-unconfigured
  '

# Para (NOVO):
entrypoint: |
  sh -c '
  export PATH="$PATH:/root/.nvm/versions/node/v20.8.0/bin"
  openclaw onboarding 2>/dev/null || true
  mkdir -p /home/openclaw/.openclaw /home/openclaw/logs /home/openclaw/.config/openclaw
  openclaw gateway --port 18789 --token "seu_token_aqui_550e8400-e29b-41d4-a716-446655440000"
  '
```

Reiniciar:
```powershell
docker-compose -f docker-compose-integrated.yml down
docker-compose -f docker-compose-integrated.yml up -d --build
```

---

## 🔓 MÉTODO 3: Via Password (Mais Fácil para Usuário)

Se achar token confuso, use **senha** ao invés:

**Editar `entrypoint.sh`:**

De:
```bash
openclaw gateway --port 18789 --allow-unconfigured
```

Para:
```bash
openclaw gateway --port 18789 --auth password --password "MinhaSenh@123"
```

**Reiniciar:**
```powershell
docker-compose -f docker-compose-integrated.yml up -d --build
```

**Acessar:**
- Abra http://localhost
- Ele pede a senha na primeira vez
- Pronto!

---

## ✅ Como Verificar se Token Está Funcionando

### 1. Ver logs
```powershell
docker logs openclaw | Select-String "token"
```

Se token ativo, vê:
```
[gateway] token authentication enabled
```

### 2. Tentar acessar sem token
```
http://localhost/
```

Esperado: **Erro 401 ou mensagem "unauthorized: gateway token mismatch"**

### 3. Acessar com token correto
```
http://localhost/?token=seu_token_aqui
```

Esperado: **Carrega dashboard normalmente**

### 4. Acessar com token errado
```
http://localhost/?token=token_errado_xyz
```

Esperado: **Erro "unauthorized: gateway token mismatch"**

---

## 🎯 Qual Método Escolher?

| Método | Dificuldade | Recomendado Para |
|--------|-----------|------------------|
| Método 1 (.env) | ⭐ Fácil | Produção - mais organization |
| Método 2 (docker-compose) | ⭐⭐ Médio | Teste rápido |
| Método 3 (Password) | ⭐ Fácil | Usuário não-técnico |

**Recomendação:** Método 1 (via .env) - é padrão, limpo e profissional.

---

## ⚠️ Problemas Comuns

### Problema: "token: command not found"
**Causa:** Typo na sintaxe  
**Solução:** Verificar aspas e espaços corretamente
```bash
# ❌ Errado
openclaw gateway --port 18789 --token seu_token_aqui

# ✅ Certo
openclaw gateway --port 18789 --token "seu_token_aqui"
```

### Problema: Mesmo com token certo, pede auth novamente
**Causa:** Token mudou e browser guardou antigo (cache)  
**Solução:** Limpar localstorage
```javascript
// No console do browser (F12):
localStorage.clear()
// Recarregar página
```

### Problema: Não consigo lembrar qual token usei
**Solução:** Ver em docker logs
```powershell
docker inspect openclaw | grep -i token
# Ou ver no .env
Get-Content .env | grep OPENCLAW_TOKEN
```

### Problema: Preciso trocar o token já ativado
**Solução:** 
```powershell
# 1. Editar .env com novo token
# 2. Parar e reiniciar
docker-compose down
docker-compose -f docker-compose-integrated.yml up -d --build
# 3. Browser pedirá novo token
```

---

## 🔒 Segurança: Dicas Importantes

1. **Use UUID (recomendado):**
   ```powershell
   [guid]::NewGuid().ToString()
   # Muito mais seguro que "senha123"
   ```

2. **Guarde o token seguro:**
   - Não compartilhe publicamente
   - Guarde em `.env` com `.gitignore`
   - Geralmente não precisa decorar

3. **Para cada ambiente:**
   ```bash
   # Dev (.env.local):
   OPENCLAW_TOKEN=seu_token_dev

   # Produção (.env.prod):
   OPENCLAW_TOKEN=outro_token_super_secreto
   ```

4. **Se vazar o token:**
   ```powershell
   # Gerar novo
   [guid]::NewGuid().ToString()
   
   # Atualizar .env
   # Reiniciar container
   # Pronto - token antigo não funciona mais
   ```

---

## 🆘 Teste Rápido de Conectividade

Quer confirmar se o OpenClaw está respondendo com token?

```powershell
# Instalar curl (se não tiver):
choco install curl

# Testar
curl -I "http://localhost/?token=seu_token_aqui"

# Esperado:
# HTTP/1.1 200 OK
# Content-Type: text/html
```

---

## 📖 Referência Completa do Comando

```bash
openclaw gateway \
  --port 18789 \                    # Porta do gateway
  --token "seu_token" \              # Token de auth (STRING, não é comando)
  --auth password \                  # Modo: token (padrão) ou password
  --password "sua_senha" \           # Se usar --auth password
  --allow-unconfigured \             # Permite sem config (atual)
  --bind loopback \                  # localhost only
  --force                            # Kill processo anterior na porta
```

---

## ✨ Exemplo Completo (Copy-Paste Pronto)

**1. Gerar token:**
```powershell
$MYTOKEN = [guid]::NewGuid().ToString()
Write-Host "Seu novo token: $MYTOKEN"
```

**2. Editar `.env`:**
```bash
OPENCLAW_TOKEN=550e8400-e29b-41d4-a716-446655440000
```

**3. Editar `entrypoint.sh` (última linha):**
```bash
openclaw gateway --port 18789 --token "${OPENCLAW_TOKEN}"
```

**4. Restart:**
```powershell
cd e:\openclaw-docker
docker-compose -f docker-compose-integrated.yml down
docker-compose -f docker-compose-integrated.yml up -d --build
```

**5. Acessar:**
```
http://localhost/?token=550e8400-e29b-41d4-a716-446655440000
```

**6. Pronto!** ✅

---

*Last Updated: 2026-02-10*
