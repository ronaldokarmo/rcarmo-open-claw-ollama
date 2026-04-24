# Guia de Validação - Cache de Agentes

## ✅ Validação da Melhoria 1: Dockerfile Multi-stage

### Passos:

1. **Verificar build completo**:
   ```bash
   docker build -t openclaw:latest .
   ```

2. **Verificar tamanho da imagem**:
   ```bash
   docker images openclaw:latest
   # Esperado: < 1GB
   ```

3. **Executar container de teste**:
   ```bash
   docker run -d \
     --name test-openclaw \
     -p 8000:8000 \
     -v e:/openclaw-docker/data:/app/data \
     openclaw:latest
   
   # Verificar logs
   docker logs test-openclaw
   ```

4. **Testar API**:
   ```bash
   curl http://localhost:8000/health
   # Esperado: {"status":"healthy"}
   ```

### Critérios de Sucesso:

- ✅ Build sem erros
- ✅ Imagem < 1GB
- ✅ Container inicia
- ✅ API responde

---

## ✅ Validação da Melhoria 2: Cache de Agentes

### Passos:

1. **Verificar arquivos criados**:
   ```bash
   ls -la /opt/openclaw/src/clauses/cache/
   ls -la /opt/openclaw/src/clauses/integrations/
   ```

2. **Verificar cache-config**:
   ```bash
   cat /opt/openclaw/cache/config
   ```

3. **Testar via Python**:
   ```bash
   cd /opt/openclaw
   python3 -c "from clauses.cache.agent_cache import AgentCache; c = AgentCache(); c.store_response('test', 'hello', 'resposta'); r = c.get_cached_response('test', 'hello'); print('SUCESSO' if r == 'resposta' else 'ERRO')"
   ```

4. **Verificar estatísticas**:
   ```bash
   python3 -c "from clauses.cache.agent_cache import AgentCache; c = AgentCache(); print(c.get_cache_stats())"
   ```

### Critérios de Sucesso:

- ✅ Arquivos de cache existem
- ✅ `store_response()` grava
- ✅ `get_cached_response()` recupera
- ✅ `get_cache_stats()` retorna dados válidos

---

## 🔧 Solução para Erro de Credenciais

Se aparecer erro `failed to get credentials`:

### Opção 1: Usar imagem diferente
```bash
docker build --build-arg NODE_VERSION=20 -t openclaw:latest .
```

### Opção 2: Limpar cache Docker
```bash
docker builder prune -a
docker system prune -v
```

### Opção 3: Configurar credenciais
```bash
docker login
# Seguir instruções para credenciais
```

### Opção 4: Usar registry local
```bash
docker pull node:20-alpine
# Depois usar nome local do image
```

---

## 📊 Checklist Completo

```bash
# 1. Build
docker build -t openclaw:latest .

# 2. Verificar tamanho
docker images openclaw:latest

# 3. Executar
docker run -d --name openclaw -p 8000:8000 openclaw:latest

# 4. Testar API
curl http://localhost:8000/health

# 5. Verificar logs
docker logs openclaw

# 6. Testar cache (via container exec)
docker exec openclaw python3 -c "from clauses.cache.agent_cache import AgentCache; c = AgentCache(); c.store_response('test', 'hello', 'resposta'); r = c.get_cached_response('test', 'hello'); print('OK' if r else 'FAIL')"

# 7. Limpeza
docker stop openclaw
docker rm openclaw
```

---

## 🐛 Troubleshooting

### Build falha no primeiro stage:
```bash
docker build --progress=plain .
# Verificar output para erro específico
```

### Build falha no segundo stage:
```bash
docker build --no-cache .
# Reinstalar todas as dependências
```

### Container não inicia:
```bash
docker logs openclaw
docker inspect openclaw
```

### Cache não funciona:
```bash
docker exec openclaw python3 -c "from clauses.cache.agent_cache import AgentCache; c = AgentCache(); print(c.get_cache_stats())"
```
