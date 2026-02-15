# ✅ OpenClaw + Ollama - Checklist de Implementação

## 📋 FASE 1: Preparação

- [ ] Ler `RESUMO_EXECUTIVO.md` (entender o plano)
- [ ] Ler `OPENCLAW_OLLAMA_INTEGRATION.md` (entender as opções)
- [ ] Fazer backup dos dados atuais:
  ```bash
  cp -r data data.backup
  cp -r logs logs.backup
  ```
- [ ] Revisar arquivo `.env.example`
- [ ] Copiar `.env.example` → `.env` e preencher API keys
- [ ] Revisar `docker-compose-integrated.yml`
- [ ] Revisar `nginx/conf.d/integrated.conf`

**Status**: ⏳ Aguardando

---

## 🚀 FASE 2: Deploy

- [ ] Parar setup atual sem perder dados:
  ```bash
  docker-compose -f docker-compose-openclaw.yml down
  docker-compose -f doker-compose-ollama.yml down
  ```

- [ ] Usar novo compose:
  ```bash
  cp docker-compose-integrated.yml docker-compose.yml
  # OU executar script automático:
  chmod +x setup-ollama.sh
  ./setup-ollama.sh auto
  ```

- [ ] Aguardar containers iniciarem (~30-60s)

- [ ] Verificar status:
  ```bash
  docker-compose ps
  ```

**Status**: ⏳ Aguardando

---

## 📥 FASE 3: Models & Configuration

- [ ] Pull do modelo principal (llama2):
  ```bash
  docker exec ollama ollama pull llama2
  ```

- [ ] (Opcional) Pull de modelo secundário:
  ```bash
  docker exec ollama ollama pull mistral
  ```

- [ ] Listar modelos disponíveis:
  ```bash
  docker exec ollama ollama list
  ```

- [ ] Editar `.env` com variáveis Ollama:
  - `OLLAMA_API_URL=http://ollama:11434`
  - `OLLAMA_MODEL=llama2`

**Status**: ⏳ Aguardando

---

## 🧪 FASE 4: Testes

### Teste 1: Ollama API
- [ ] Testar connectividade:
  ```bash
  curl http://localhost:11434/api/tags
  ```
  **Esperado**: JSON com lista de modelos

### Teste 2: OpenClaw → Ollama
- [ ] Testar de dentro do container:
  ```bash
  docker exec openclaw curl http://ollama:11434/api/tags
  ```
  **Esperado**: Mesmo resultado acima

### Teste 3: Nginx Proxy
- [ ] Testar acesso via proxy:
  ```bash
  curl -I http://localhost:80
  ```
  **Esperado**: HTTP/1.1 200 OK

### Teste 4: OpenClaw Gateway
- [ ] Gerar token de acesso:
  ```bash
  docker exec openclaw openclaw doctor --generate-gateway-token
  ```
  **Esperado**: Token (copie este!)

### Teste 5: Dashboard
- [ ] Acessar dashboard:
  ```
  http://localhost/?token=<COLE_AQUI>
  ```
  **Esperado**: Interface OpenClaw carregando

### Teste 6: Open-WebUI (Opcional)
- [ ] Acessar interface Ollama:
  ```
  http://localhost:3000
  ```
  **Esperado**: Interface Open-WebUI funcional

### Teste 7: Logs
- [ ] Verificar logs para erros:
  ```bash
  docker logs openclaw -f
  docker logs ollama -f
  docker logs openclaw-proxy -f
  ```
  **Esperado**: Sem erro críticos, apenas info/warn

**Status**: ⏳ Aguardando

---

## 📊 FASE 5: Validação & Monitoramento

- [ ] Todos os containers rodando:
  ```bash
  docker-compose ps
  # Esperado: All "Up" status
  ```

- [ ] Uso de recursos OK:
  ```bash
  docker stats --no-stream
  # Esperado: RAM <8GB, CPU <50% em idle
  ```

- [ ] Dados persistindo:
  ```bash
  ls -la data/
  ls -la ollama_data/
  ```
  **Esperado**: Diretórios não vazios

- [ ] Modelos baixados:
  ```bash
  du -sh ollama_data/
  # Esperado: ~7GB+ (depende do modelo)
  ```

- [ ] Performance aceitável:
  ```bash
  # Testar geração de texto (pode levar alguns segundos)
  curl http://localhost:11434/api/generate \
    -d '{"model":"llama2","prompt":"Hi","stream":false}'
  ```
  **Esperado**: Resposta JSON com texto

**Status**: ⏳ Aguardando

---

## 🔧 FASE 6: Ajustes Finais

### Ambiente
- [ ] Verificar variáveis de ambiente:
  ```bash
  docker exec openclaw env | grep OLLAMA
  ```

- [ ] Se necessário, reconfigurar:
  ```bash
  docker exec openclaw openclaw config set OLLAMA_API_URL http://ollama:11434
  ```

### SSL/HTTPS (se desejar)
- [ ] Gerar certificados (opcional):
  ```bash
  mkdir -p nginx/ssl
  # Gerar ou copiar certificados para nginx/ssl/
  ```

- [ ] Atualizar `nginx/conf.d/integrated.conf` com server HTTPS

- [ ] Restart Nginx:
  ```bash
  docker-compose restart openclaw-proxy
  ```

### Persistência
- [ ] Confirmar volumes mapeados:
  ```bash
  docker inspect openclaw | grep -A 10 Mounts
  ```

- [ ] Testar restart sem perda de dados:
  ```bash
  docker-compose down
  docker-compose up -d
  docker exec ollama ollama list
  # Esperado: Modelos continuam lá
  ```

**Status**: ⏳ Aguardando

---

## 📚 FASE 7: Documentação Local

- [ ] Criar documento local com URLs:
  ```
  OpenClaw: http://localhost/?token=ABC123...
  Ollama:   http://localhost:11434
  WebUI:    http://localhost:3000
  ```

- [ ] Documentar modelos em uso:
  ```
  - llama2 (7B, ~7GB)
  - mistral (7B, ~25GB)
  ```

- [ ] Criar scripts de manutenção:
  ```bash
  # backup.sh - script para backup
  # restart.sh - script para reiniciar
  # logs.sh - script para monitorar logs
  ```

- [ ] Documentar processo de rollback (se necessário)

**Status**: ⏳ Aguardando

---

## 🆘 TROUBLESHOOTING

### Se algo der errado:

- [ ] Verificar logs primeiro:
  ```bash
  docker logs openclaw
  docker logs ollama
  docker logs openclaw-proxy
  ```

- [ ] Testar conectividade de rede:
  ```bash
  docker exec openclaw ping ollama
  ```

- [ ] Verificar DNS:
  ```bash
  docker exec openclaw nslookup ollama
  ```

- [ ] Reiniciar networks:
  ```bash
  docker-compose down
  docker-compose up -d
  ```

- [ ] Se persistir, rollback:
  ```bash
  docker-compose down -v
  rm -rf data logs ollama_data open_webui_data
  cp -r data.backup data
  cp -r logs.backup logs
  docker-compose -f docker-compose-openclaw.yml up -d
  ```

**Status**: ⏳ Aguardando

---

## ✨ FASE 8: Uso & Customização (Opcional)

- [ ] Explorar models diferentes de Ollama
- [ ] Configurar skills customizados no OpenClaw
- [ ] Conectar outras ferramentas/APIs
- [ ] Setup de monitoring (Prometheus, Grafana)
- [ ] Backup automático de dados

**Status**: ⏳ Aguardando

---

## 📈 Progresso Geral

```
Preparação:       ░░░░░░░░░░  0%
Deploy:           ░░░░░░░░░░  0%
Models:           ░░░░░░░░░░  0%
Testes:           ░░░░░░░░░░  0%
Validação:        ░░░░░░░░░░  0%
Ajustes:          ░░░░░░░░░░  0%
Documentação:     ░░░░░░░░░░  0%
Uso & Custom:     ░░░░░░░░░░  0%

TOTAL:            ░░░░░░░░░░  0%
```

Atualize conforme progride!

---

## 🎯 Próxima Ação

**Recomendado agora:**

```bash
# 1. Entender o plano
cat RESUMO_EXECUTIVO.md

# 2. Fazer backup
cp -r data data.backup && cp -r logs logs.backup

# 3. Executar setup automático
chmod +x setup-ollama.sh
./setup-ollama.sh auto

# 4. Acompanhar os logs
docker-compose logs -f
```

---

## 🚀 Sucesso!

Quando tudo estiver OK:

```
✅ OpenClaw Dashboard acessível
✅ Ollama respondendo em localhost:11434  
✅ OpenClaw consegue chamar Ollama
✅ Modelos disponíveis e funcionando
✅ Dados persistindo após restart
✅ Logs limpos (sem erros críticos)
✅ Performance aceitável
```

**Parabéns! 🎉 Seu sistema OpenClaw + Ollama está pronto!**

---

## 📞 Contato & Suporte

Se precisar de ajuda:
1. Releia `OPENCLAW_OLLAMA_INTEGRATION.md`
2. Verifique logs: `docker logs <container>`
3. Teste conectividade: `docker exec openclaw curl http://ollama:11434/api/tags`
4. Consulte troubleshooting acima

**Boa sorte! 🦞**
