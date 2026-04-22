# Plano de Correção e Expansão Multiagentes

## Compreendendo o Problema Atual

Acabei de investigar a estrutura do seu projeto e descobri exatamente **por que os tutores `tutor-english` e `tutor-iot` não estão funcionando**:

1. Embora você tenha os arquivos de instruções (`tutor-iot-system.md`, etc) soltos na pasta `multiagents-openclaw/`, a estrutura real que o OpenClaw lê fica dentro de `data/.openclaw/agents/`. Atualmente, apenas o agente `main` existe lá dentro!
2. O arquivo de configuração mestre que rege tudo (`data/.openclaw/openclaw.json`) só tem o agente `main` registrado na lista de roteamento. Ele perdeu o registro dos outros agentes.

Vamos corrigir isso de uma vez por todas e aproveitar o embalo para criar o novo **Prompt Engineer**.

---

## Passo a Passo da Implementação

### 1. Recriar a Estrutura Física dos Agentes

O OpenClaw espera que cada agente tenha seu próprio diretório contendo suas instruções (`system.md`). Vou criar a estrutura de pastas e injetar os prompts:

#### [NEW] [tutor-english/agent/system.md](file:///e:/openclaw-docker/data/.openclaw/agents/tutor-english/agent/system.md)
Conteúdo: Cópia exata de `multiagents-openclaw/tutor-english-system-v4-com-avaliacao.md`.

#### [NEW] [tutor-iot/agent/system.md](file:///e:/openclaw-docker/data/.openclaw/agents/tutor-iot/agent/system.md)
Conteúdo: Cópia exata de `multiagents-openclaw/tutor-iot-system.md`.

#### [NEW] [prompt-engineer/agent/system.md](file:///e:/openclaw-docker/data/.openclaw/agents/prompt-engineer/agent/system.md)
Conteúdo: O prompt de arquitetura e otimização de instruções que você forneceu.

---

### 2. Registrar os Agentes para Roteamento (openclaw.json)

Vou modificar o arquivo de configuração atual (`data/.openclaw/openclaw.json`) para que o `main` saiba identificar quando deve "chamar" cada um desses supervisores com base no que você disser.

#### [MODIFY] [openclaw.json](file:///e:/openclaw-docker/data/.openclaw/openclaw.json)

Alterarei o bloco `agents.list` para:

```json
    "list": [
      {
        "id": "main",
        "model": "ollama/kimi-k2.5:cloud"
      },
      {
        "id": "tutor-english",
        "name": "Professor de Inglês",
        "model": "ollama/qwen3.5:9b",
        "keywords": ["english", "inglês", "grammar", "vocabulary", "translate", "how do you say", "corrija"]
      },
      {
        "id": "tutor-iot",
        "name": "Engenheiro IoT",
        "model": "ollama/qwen3.5:9b",
        "keywords": ["arduino", "esp32", "sensor", "circuit", "mqtt", "i2c", "pinMode"]
      },
      {
        "id": "prompt-engineer",
        "name": "Prompt Architect",
        "model": "ollama/qwen3.5:9b",
        "keywords": ["refatorar prompt", "melhorar prompt", "prompt", "otimizar instrução", "Claude Code"]
      }
    ]
```
*(Nota: Ajustei o modelo padrão deles para `qwen3.5:9b` assumindo que é o seu principal. O Main fica com o Kimi Cloud.)*

---

### 3. Aplicação e Verificação

Após as configurações de arquivo:
1. Executarei `docker compose restart openclaw` para que a configuração seja carregada na memória do Gateway.
2. Checarei se a estrutura na pasta `data/.openclaw/agents/` ficou correta e as devidas permissões de dono (`chown`) estão atribuídas para evitar falha no Linux/WSL.

### Teste Simulado
O fluxo de resolução passará a ser:
- Você diz: *"Me ajude com o present perfect"*. O OpenClaw enxerga "english/grammar" -> Manda pro `tutor-english`.
- Você diz: *"Pode melhorar este prompt que criei?"*. O OpenClaw enxerga "melhorar prompt" -> Manda pro `prompt-engineer`.

> [!IMPORTANT]
> **Open Question:** Para os três sub-agentes, configurei o modelo `ollama/qwen3.5:9b` por ser o local que você tem instalado. Se você quiser que o Prompt Engineer ou os outros usem o Kimi Cloud ou outro modelo da sua lista, me avise antes da execução!
