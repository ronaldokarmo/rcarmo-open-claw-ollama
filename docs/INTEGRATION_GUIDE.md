# 🚀 Guia de Integração: OpenClaw + Ollama

## Análise & Recomendações

### ✅ Estrutura Melhorada

A nova configuração (`docker-compose-integrated.yml`) consolida tudo em:
- **OpenClaw**: Aplicação principal
- **Ollama**: LLM backend local
- **Open-WebUI**: Interface web para Ollama (opcional)
- **Nginx**: Proxy reverso centralizado

### 📋 Mudanças Principais

#### 1. **Redes Compartilhadas**
- Todos os serviços agora usam a mesma rede `openclaw-net`
- OpenClaw consegue acessar Ollama via `http://ollama:11434`
- Docker resolve automaticamente os nomes dos serviços

#### 2. **Volumes Consolidados**
```yaml
ollama_data:        # Modelos e cache do Ollama
open_webui_data:    # Dados do Open-WebUI
```

#### 3. **Portas Gerenciadas**
| Serviço | Porta Interna | Porta Externa | Acesso |
|---------|--------------|--------------|--------|
| OpenClaw | 18789 | 80/443 | http://localhost |
| Ollama | 11434 | 11434 | http://localhost:11434 |
| OpenClaw Direto | 18789 | 18790 | http://localhost:18790 |
| Open-WebUI | 3000 | 3000 | http://localhost:3000 |

---

## 🔧 Como Implementar

### Opção A: Usar a Nova Configuração (Recomendado)

```bash
# 1. Remova os containers antigos
docker-compose -f docker-compose-openclaw.yml down -v

# 2. Use o novo arquivo integrado
docker-compose -f docker-compose-integrated.yml up -d

# 3. Verifique o status
docker-compose -f docker-compose-integrated.yml ps
```

### Opção B: Manter Separados (Se Preferir)

Se quiser manter dois arquivos separados:

```bash
# Terminal 1: OpenClaw
docker-compose -f docker-compose-openclaw.yml up -d

# Terminal 2: Ollama
docker-compose -f doker-compose-ollama.yml up -d
```

⚠️ **Problema**: Os containers estarão em redes diferentes:
- Você precisará expor todas as portas
- OpenClaw **não conseguirá** acessar Ollama facilmente
- Configurações mais complexas no Nginx

---

## 🔌 Configuração do OpenClaw para Usar Ollama

### Method 1: Via Variável de Ambiente

Se OpenClaw suporta, adicione no `docker-compose-integrated.yml`:
```yaml
environment:
  OLLAMA_API_URL: http://ollama:11434
  OLLAMA_MODEL: llama2  # ou outro modelo disponível
```

### Method 2: Arquivo de Configuração

Edite `config/custom-config.yaml`:
```yaml
models:
  ollama:
    enabled: true
    api_url: http://ollama:11434
    models:
      - llama2
      - mistral
      # adicione outros modelos disponíveis
```

### Method 3: Interface do OpenClaw

Se OpenClaw tem UI de settings, configure:
- **API URL**: `http://ollama:11434`
- **Modelos**: `llama2`, `mistral`, etc.

---

## 📥 Pull de Modelos Ollama

Os modelos precisam ser baixados antes de usar:

```bash
# Aceda o container Ollama
docker exec -it ollama ollama list

# Baixe um modelo
docker exec -it ollama ollama pull llama2
docker exec -it ollama ollama pull mistral
docker exec -it ollama ollama pull neural-chat
```

Ou via API:
```bash
curl http://localhost:11434/api/pull -d '{"name":"llama2"}'
```

---

## 🌐 Acessando os Serviços

```
OpenClaw:     http://localhost
OpenClaw:     http://localhost:18790 (acesso direto)
Ollama API:   http://localhost:11434
Open-WebUI:   http://localhost:3000  (opcional)
```

---

## 🧪 Testes

### 1. Verificar conectividade
```bash
# De dentro do container openclaw
docker exec openclaw curl http://ollama:11434/api/tags

# Deveria retornar os modelos disponíveis
```

### 2. Testar Ollama diretamente
```bash
curl http://localhost:11434/api/tags
curl http://localhost:11434/api/generate -d '{"model":"llama2","prompt":"Hello"}'
```

### 3. Verificar logs
```bash
docker logs openclaw
docker logs ollama
docker logs openclaw-proxy
```

---

## 📝 Checklist de Implementação

- [ ] Revisar `docker-compose-integrated.yml`
- [ ] Revisar `nginx/conf.d/integrated.conf`
- [ ] Definir como OpenClaw será configurado para usar Ollama
- [ ] Download dos modelos Ollama necessários
- [ ] Testar conectividade entre os containers
- [ ] Configurar custom-config.yaml se necessário
- [ ] Atualizar variáveis de ambiente (.env)
- [ ] Testar acesso via navegador

---

## 📞 Próximos Passos

1. **Confirme** como o OpenClaw precisa ser configurado para usar Ollama
   - Busque na documentação do OpenClaw
   - Verifique os arquivos de configuração existentes
   
2. **Defina** quais modelos Ollama você quer usar
   - Llama2, Mistral, Neural-Chat, etc.
   
3. **Configure** HTTPS se necessário
   - Gere certificados SSL
   - Atualize a config Nginx

4. **Teste** a integração completa antes de colocar em produção

---

## ⚠️ Considerações de Performance

- **Ollama** é CPU/memória intensivo - verifique recursos disponíveis
- **Modelos grandes** (7B+) necessitam 8GB+ RAM
- Considere usar modelos menores em produção (quantized versions)
- Monitore com `docker stats` durante testes

---

## 📚 Referências

- [Ollama Docs](https://ollama.ai)
- [Open-WebUI Docs](https://github.com/open-webui/open-webui)
- [Docker Compose Networking](https://docs.docker.com/compose/networking/)
