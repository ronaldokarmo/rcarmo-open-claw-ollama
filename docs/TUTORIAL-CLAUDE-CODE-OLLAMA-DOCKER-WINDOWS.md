# Tutorial: Configurando Claude Code com Ollama no Docker (Windows)

Este tutorial mostra como conectar o **Claude Code** aos modelos do **Ollama** executando em **Docker Desktop** no Windows, usando a configuração existente do seu projeto.

## Pré-requisitos

- Docker Desktop em execução no Windows
- Ollama container rodando (sua configuração já tem isso em `docker-compose.yml`)
- Claude Code instalado no Windows

---

## 1. Verificar se o Ollama está acessível

Antes de prosseguir, certifique-se de que o container Ollama está rodando e acessível na porta 11434:

```powershell
# Testar conexão com Ollama no Docker
curl http://localhost:11434
```

Você deve ver uma resposta como: `"Ollama is running"`

Se não funcionar, verifique se os containers estão rodando:

```powershell
docker ps
```

---

## 2. Configurar Variáveis de Ambiente (Windows)

O Ollama no Docker expõe a API na porta **11434** do localhost. Você precisa configurar o Claude Code para usar essa URL.

### Método A: Configuração Temporária (PowerShell)

Defina as variáveis antes de executar o Claude Code:

```powershell
$env:ANTHROPIC_AUTH_TOKEN = "ollama"
$env:ANTHROPIC_BASE_URL = "http://localhost:11434"
$env:ANTHROPIC_API_KEY = "ollama"
```

### Método B: Configuração Permanente (PowerShell)

Adicione ao seu perfil do PowerShell para não precisar configurar a cada sessão:

```powershell
# Abrir arquivo de perfil
notepad $PROFILE

# Adicionar estas linhas:
$env:ANTHROPIC_AUTH_TOKEN = "ollama"
$env:ANTHROPIC_BASE_URL = "http://localhost:11434"
$env:ANTHROPIC_API_KEY = "ollama"
```

### Método C: Arquivo de Configuração do Claude Code

Crie um arquivo de configuração em `~/.claude/settings.json`:

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "ollama",
    "ANTHROPIC_BASE_URL": "http://localhost:11434",
    "ANTHROPIC_API_KEY": "ollama"
  }
}
```

---

## 3. Listar Modelos Disponíveis

Verifique quais modelos estão disponíveis no Ollama do Docker:

```powershell
curl http://localhost:11434/api/tags
```

A resposta incluirá uma lista de modelos como:
- `qwen2.5:1.5b`
- `glm-4.7-flash`
- `kimi-k2.5:cloud`

---

## 4. Executar o Claude Code com Modelo Específico

Agora você pode iniciar o Claude Code apontando para um modelo específico do Ollama:

```powershell
# Com variáveis de ambiente configuradas
claude --model qwen2.5:1.5b
```

Ou para usar um modelo de nuvem do Ollama:

```powershell
claude --model glm-4.7-flash
```

### Exemplo Completo (uma linha)

```powershell
$env:ANTHROPIC_AUTH_TOKEN="ollama"; $env:ANTHROPIC_BASE_URL="http://localhost:11434"; $env:ANTHROPIC_API_KEY="ollama"; claude --model qwen2.5:1.5b
```

---

## 5. Modelos Recomendados para Claude Code

| Tipo | Modelo | Descrição |
|------|--------|------------|
| **Nuvem** | `glm-4.7-flash` | Modelo rápido do Ollama Cloud |
| **Nuvem** | `kimi-k2.5:cloud` | Modelo Kimi no Ollama |
| **Nuvem** | `glm-5:cloud` | Novo modelo GLM |
| **Local** | `qwen2.5:1.5b` | Modelo pequeno para testes |
| **Local** | `qwen3-coder` | Modelo para código (se disponível) |

---

## 6. Troubleshooting

### "Connection refused"

- Verifique se o Docker Desktop está rodando
- Confirme que o container `ollama` está em execução: `docker ps`
- Teste a porta: `telnet localhost 11434`

### "Model not found"

- Liste os modelos disponíveis: `curl http://localhost:11434/api/tags`
- Use o nome exato do modelo (sem tags adicionais)

### Ollama não carrega o modelo

- O Docker pode estar sem memória suficiente
- Reduza o `OLLAMA_NUM_PARALLEL` no `docker-compose.yml`

---

## 7. Configuração Opcional: .env do Projeto

Se você quiser que o OpenClaw use o Ollama do Docker, verifique seu arquivo `.env`:

```env
OLLAMA_API_BASE=http://ollama:11434
OLLAMA_API_KEY=ollama-local
OPENCLAW_MODEL=ollama/qwen2.5:1.5b
```

---

## Resumo

| Componente | URL/Porta |
|------------|-----------|
| Ollama (Docker) | `http://localhost:11434` |
| Variável `ANTHROPIC_BASE_URL` | `http://localhost:11434` |
| Variável `ANTHROPIC_AUTH_TOKEN` | `ollama` |
| Variável `ANTHROPIC_API_KEY` | `ollama` |

---

## Próximos Passos

1. Execute `docker-compose up -d` para garantir que tudo está rodando
2. Configure as variáveis de ambiente conforme Método C
3. Execute `claude --model glm-4.7-flash` para testar

Para mais informações, consulte:
- [Documentação Ollama + Claude Code](https://docs.ollama.com/integrations/claude-code)
- [Blog: Claude Code com Ollama](https://www.datacamp.com/tutorial/using-claude-code-with-ollama-local-models)