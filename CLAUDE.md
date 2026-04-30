# OpenClaw - Multiagent System Documentation

> **Versão:** Enterprise Edition v1.0  
> **Data:** 5 de abril de 2026  
> **Status:** 🚀 **Operacional**

---

## 🎯 Visão Geral

OpenClaw é um **Multiagent System** Dockerizado para **Test Engineers** que busca fluência em **Inglês Técnico** usando **Obsidian** como Second Brain.

### Arquitetura Principal

```
┌─────────────────────────────────────────────────────────┐
│              Docker Container                            │
│  ┌───────────────────────────────────────────────────┐  │
│  │         OpenClaw Qwen-3.5 (QWEN-3.5)              │  │
│  │                                                 │  │
│  │  ┌───────────┐    ┌─────────────┐               │  │
│  │  │  Webchat  │    │  Telegram   │               │  │
│  │  │  :18790   │    │  Bot        │               │  │
│  │  └───────────┘    └─────────────┘               │  │
│  │                                                 │  │
│  │  ┌────────────────────────────────────────────┐ │  │
│  │  │       Rede de Agentes (Multiagents)       │ │  │
│  │  │                                           │ │  │
│  │  │  • Main (Roteador Geral)                  │ │  │
│  │  │  • Tutor English (Aulas de Inglês)        │ │  │
│  │  │  • Tutor IoT (Hardware e IoT)             │ │  │
│  │  │  • Prompt Engineer (Otimização de Prompts)│ │  │
│  │  └────────────────────────────────────────────┘ │  │
│  │                                                 │  │
│  │  🧠 Memory-Wiki (memory-wiki.md)                 │  │
│  │                                                 │  │
│  │  🗃️ Obsidian Vault Mount                        │  │
│  │     - Knowledge/ (Documentação)                  │  │
│  │     - Memory/ (Logs e Memórias)                  │  │
│  │     - Projects/ (Projetos)                      │  │
│  └─────────────────────────────────────────────────┘  │
│                                                     │
│  🔧 Skills: memory-wiki, obsidian-vault-writer       │
└───────────────────────────────────────────────────────┘
         │
         ▼
  ┌────────────────────────────────────────────────────┐
│           E:\obsidian\OpenClaw (Volume Mount)         │
│  ┌─────────────────────────────────────────────────┐ │
│  │  - Knowledge/ (Documentação)                     │ │
│  │  - Memory/ (Logs e Memórias)                     │ │
│  │  - Projects/ (Projetos)                         │ │
│  └─────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
```

---

## 🏗️ Estrutura de Pastas

### Docker Container

```
/app/
├── openclaw/
│   └── logs/                    # Logs do OpenClaw
│       └── openclaw-log-001.log
├── data/
│   └── vault/                  # Mount do Obsidian Vault
│       └── (conteúdo do vault)
└── memory-wiki/
    └── memory-wiki.md          # Log filosófico
```

### Host Windows

```
E:\obsidian\OpenClaw\
├── Knowledge/
│   ├── Obsidian/              # Documentação do Obsidian
│   ├── Idiomas/
│   │   └── Inglês/
│   │       └── Caderno-de-Estudos/
│   │           ├── aula-ingles.md
│   │           ├── ingles-americano-para-test-engineer.md
│   │           ├── English_Master_Study_Plan.md
│   │           └── [outros materiais]
│   └── OpenClaw-Docs/         # Documentação oficial
│       ├── Biblioteca_OpenClaw.md
│       ├── Manual_OpenClaw_UI.md
│       ├── Mapa_de_Evolucao.md
│       ├── Nota_para_o_usuario.md
│       ├── OpenClaw-Memory-Log.md
│       └── vault.md
├── Memory/
│   ├── OpenClaw-Memory-Log/   # Logs históricos migrados
│   ├── daily/                 # Logs diários da IA
│   │   ├── 2025-05-14.md
│   │   └── [logs diários]
│   └── MEMORY.md              # Memórias distiladas
└── Projects/
    └── Setup-Multiagentes/
        ├── docker-compose.yml
        └── Dockerfile
```

---

## 🚀 Como Usar

### Iniciar o Ambiente

```powershell
cd e:\openclaw-docker
docker-compose up -d
```

### Acessar as Interfaces

- **Webchat:** `http://localhost:18790`
- **Telegram:** Bot no Telegram

### Comandos Úteis

```
/list - Listar todos os agentes
/loop - Ativar loop contínuo de estudos
/heartbeat - Ativar distilação de memória
```

---

## 🤖 Rede de Agentes

### Agentes Disponíveis

| Agente | Specialidade | Quando Usar |
|--------|-------------|-------------|
| **Atom** | Roteador geral | Início de conversação |
| **OpenClaw** | Códigos confidenciais | Debug de produção |
| **Llama-70B/8B** | Chat rápido | Dúvidas rápidas |
| **Tutor English** | Aulas de inglês | Estudos linguísticos |
| **Prompt Architect** | Otimização de prompts | Refatoração |
| **Hardware IoT** | Dispositivos IoT | Debug de hardware |
| **Observability** | Logs e dashboards | Monitoramento |
| **Security Analyst** | Segurança | Code review |

---

## 🧠 Skills do Sistema

### memory-wiki

**Função:** Leitura e escrita no arquivo `memory-wiki.md` no container.

**Usage:**
```
"Salve isso na memória."
"Buscar na memória sobre X"
```

### obsidian-vault-writer

**Função:** Ferramentas Bash para escrever no vault.

**Quando:** Quando a IA precisa persistir conhecimento.

### search-obsidian

**Função:** Leitura de arquivos `.md` no vault.

**Purpose:** Pesquisa no Second Brain.

---

## 🎯 Uso Prático

### Ativar Tutor English

```
"Vamos focar no vocabulário de Testes. Procure as regras passadas sobre Bug Reports e me lance um desafio rápido."
```

### Ativar Loop de Estudos

```
/loop
"Continue estudando inglês, revisando vocabulário de testes e aplicando os conceitos práticos.
Passo a passo:
1. Foca em palavras relacionadas a bugs e issues que você viu no Docker
2. Dá um exemplo prático usando essas palavras, se possível
3. Pede um feedback ou me tira dúvidas"
```

### Ativar Distilação de Memória

```
/heartbeat
```

---

## 📚 Material Didático

### Caderno de Estudos

Local: `Knowledge\Idiomas\Ingles\Caderno-de-Estudos\`

- **aula-ingles.md** - Fundamentos
- **ingles-americano-para-test-engineer.md** - Jargões
- **English_Master_Study_Plan.md** - Plano de estudos

---

## 📋 Logs Históricos

### OpenClaw-Memory-Log

Extraído de `.openclaw/logs` do Docker e movido para:

`Memory/OpenClaw-Memory-Log/`

Contém reflexões sobre evolução da IA, insights técnicos e aprendizados acumulados.

---

## 🔒 Segurança

- Agentes com acesso a códigos confidenciais: **OpenClaw (Qwen-3.5)**
- Agentes públicos: **Llama-70B/8B (Groq)**
- Logs rotacionados: **daily/YYYY-MM-DD.md**
- Memória distilada periodicamente

---

## 📖 Documentação

- [Manual de Uso](docs/Manual_OpenClaw_UI.md)
- [Bibliografia](docs/Biblioteca_OpenClaw.md)
- [Plano de Implementação](docs/plans/implementation_plan_v5_obsidian_learning_english.md)
- [Walkthrough](docs/plans/walkthrough_v2_obsidian.md)

### Arquivos de Referência

| Arquivo | Localização |
|---------|-------------|
| **CLAUDE.md** | `e:\openclaw-docker\CLAUDE.md` ✅ |
| **Manual OpenClaw UI** | `docs\Manual_OpenClaw_UI.md` |
| **Walkthrough** | `docs\plans\walkthrough_v2_obsidian.md` |
| **Plano de Implementação** | `docs\plans\implementation_plan_v5_obsidian_learning_english.md` |

---

## 📦 Docker Volumes

### openclaw-vault

- **Mount:** `openclaw-vault:/app/data/vault`
- **Host Path:** `E:\obsidian\OpenClaw\`
- **Conteúdo:** Second Brain completo

### openclaw-logs

- **Mount:** `openclaw-logs:/app/openclaw/logs`
- **Host Path:** `E:\obsidian\OpenClaw\Memory\`
- **Conteúdo:** Logs rotacionados

---

**Bem-vindo ao OpenClaw Enterprise Edition!** 🚀
