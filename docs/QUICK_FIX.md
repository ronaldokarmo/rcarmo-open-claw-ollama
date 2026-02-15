# ⚡ Quick Fix - Comandos Prontos para Copiar/Colar

## 🆘 SITUAÇÃO ATUAL
```
❌ Nginx: error "host not found"
❌ OpenClaw: config errors
❌ Containers reiniciando
```

## ✅ SOLUÇÃO RÁPIDA (3 passos)

### PASSO 1: Parar Tudo
```powershell
cd e:\openclaw-docker
docker-compose down
```

**Esperado**: Containers param (OK se der erro inicial)

---

### PASSO 2: Limpar (OPCIONAL - se tiver em loop)
```powershell
# Se containers estão em loop infinito:
docker-compose down -v --remove-orphans
docker container prune -f
```

**Esperado**: Containers removidos

---

### PASSO 3: Iniciar com Build
```powershell
# Copie os arquivos corrigidos
cp docker-compose-integrated.yml docker-compose.yml

# Inicie
docker-compose up -d --build
```

**Esperado**: Vê "Creating..." para cada container

---

## 📊 ACOMPANHAR SETUP (Abra outra janela Terminal)

```powershell
docker-compose logs -f
```

**Aguarde** até ver isto:
```
openclaw   | 2026-02-10T20:42:25.401Z [gateway] listening on ws://127.0.0.1:18789 (PID 101)
open-webui | INFO:     Started server process [1]
nginx      | Configuration complete; ready for start up
ollama     | time=2026-02-10T20:25:00.405Z level=INFO ... Listening on [::]:11434
```

Isto indica que **TUDO ESTÁ OK!**

---

## ✅ TESTES (Nova janela Terminal #3)

### Teste 1: Ollama API
```powershell
curl http://localhost:11434/api/tags
```

**Esperado**: JSON com modelos
```json
{"models":[]}  # ou lista modelo se já houver
```

---

### Teste 2: Status Containers
```powershell
docker-compose ps
```

**Esperado**:
```
NAME             STATUS
ollama           Up (healthy)
openclaw-proxy   Up (healthy)
openclaw         Up
open-webui       Up
```

---

### Teste 3: OpenClaw Gateway
```powershell
docker exec openclaw openclaw doctor --generate-gateway-token
```

**Esperado**: Saída com token gerado
```
Token: 3da2dbe007fe3e01d7380213e068f2d5bd15cdd5cc96d29a
```

---

### Teste 4: OpenClaw → Ollama
```powershell
docker exec openclaw curl http://ollama:11434/api/tags
```

**Esperado**: Mesmo JSON do Teste 1

---

## 🌐 ACESSAR INTERFACES

### OpenClaw Dashboard
```
http://localhost/?token=<COLE_AQUI_O_TOKEN>
```

### Ollama API
```
http://localhost:11434/api/tags
```

### Open-WebUI
```
http://localhost:3000
```

---

## ⚠️ SE ALGO AINDA FALHAR

### Opção A: Ver logs completos
```powershell
docker logs openclaw -f
docker logs openclaw-proxy -f
docker logs ollama -f
```

### Opção B: Restart limpo
```powershell
docker-compose down
docker-compose up -d --build

# Aguarde 2-3 min
docker-compose logs -f
```

### Opção C: Rollback total
```powershell
docker-compose down -v
docker volume prune -f

# Remova data/logs locais se quiser fresh start:
# rm -r data logs ollama_data

docker-compose up -d --build
```

---

## 📝 CHECKLIST RÁPIDO

- [ ] Rodei `docker-compose down`
- [ ] Rodei `docker-compose up -d --build`
- [ ] Vi "Configuration complete; ready for start up" (nginx)
- [ ] Vi "listening on ws://127.0.0.1:18789" (openclaw)
- [ ] Vi "Started server process" (open-webui)
- [ ] Testei `curl http://localhost:11434/api/tags`
- [ ] Resultado: JSON ou `{"models":[]}`

**Se todos checked**: ✅ **FUNCIONANDO!**

---

## 🚀 PRÓXIMOS COMANDOS (Após tudo OK)

### Download de Modelos Ollama

```powershell
# LLama2 (recomendado)
docker exec ollama ollama pull llama2

# Mistral (opcional)
docker exec ollama ollama pull mistral

# Listar disponíveis
docker exec ollama ollama list
```

---

## 📞 RESUMO DE CORREÇÕES APLICADAS

### ✅ Arquivo: `nginx/conf.d/integrated.conf`
- Adicionado `resolver 127.0.0.11`
- Variáveis dinâmicas para upstream

### ✅ Arquivo: `entrypoint.sh`
- Removidos comandos `config set` inválidos
- Mantém apenas variáveis de ambiente

### ✅ Arquivo: `docker-compose-integrated.yml`
- Adicionados `healthcheck` em Ollama e Nginx
- Adicionado `depends_on` com `condition: service_healthy`

---

**Está pronto? Bora lá!** 🚀

```powershell
docker-compose down
docker-compose up -d --build
docker-compose logs -f
```

Quanto tempo dura o setup?
```
- Ollama: 10-20s
- Nginx: 5-10s
- OpenClaw: 20-30s
- Open-WebUI: 30-60s (primeiro start)

Total: ~2-3 minutos
```

Boa sorte! 🦞
