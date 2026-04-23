---
name: project_ecosystem
description: Arquivo que documenta o ecossistema completo de agentes, habilidades e integração Obsidian
type: project
---

## 🔧 A Rede de Agentes (Multiagent System)

### Agentes Disponíveis no Multiagent System:

| Agente | Responsabilidade | When to Use |
|--------|------------------|-------------|
| **Atom (Kimi Cloud)** | Roteador geral da rede | Início de conversação complexa |
| **OpenClaw (Qwen-9B)** | Códigos confidenciais na sua RTX | Quando o assunto é código sensível |
| **Llama-70B/8B (Groq)** | Conversas rápidas no Telegram | Estudos, dúvidas linguísticas |
| **Prompt Architect** | Análise e refatoração de prompts | Quando o prompt falha |
| **Tutor English** | Aulas personalizadas em inglês | Estudar inglês técnico |
| **Hardware IoT Engineer** | Problemas de dispositivos IoT | Debug de hardware |
| **Observability Engineer** | Análise de logs e dashboards | Debug de aplicações |
| **Security Analyst** | Análise de segurança de código | Code review de segurança |

---

## 🎯 Skills Principais

### 1. `memory-wiki`
- **Função:** Leitura e escrita no arquivo `memory-wiki.md` no container
- **Purpose:** Distilação de memória entre daily logs e long-term memory
- **When:** Quando precisa salvar aprendizado ou buscar memória de sessão anterior

### 2. `obsidian-vault-writer`
- **Função:** Ferramentas Bash (`echo`, `cat`, `cp`, `mv`, `rm`, `mkdir`) para escrever no Obsidian
- **Purpose:** Persistência de conhecimento fora do chat volátil
- **When:** Quando a IA precisa documentar algo no seu Vault

### 3. `search-obsidian`
- **Função:** Leitura de arquivos `.md` no vault e extração de conteúdo relevante
- **Purpose:** Pesquisa no Second Brain da IA
- **When:** Para buscar informações específicas no seu conhecimento

---

## 🧠 Estrutura de Memória

```
memory/
├── user_profile.md           # Quem é o usuário
├── project_ecosystem.md      # Este arquivo
├── feedback_testing.md       # Feedback específico sobre testes
├── daily/
│   └── YYYY-MM-DD.md         # Logs diários (auto-cuidado)
└── MEMORY.md                 # Distilação: memórias permanentes
```

**Workflow de Distilação:**
- Ativa via `/heartbeat` (webchat) ou cron
- Move informações relevantes de daily para long-term
- Garante token efficiency e preservação de contexto crítico

---

## 🗃️ Vault do Usuário (Second Brain)

```
E:\obsidian\ai-data\
├── Knowledge/
│   ├── Obsidian/              # Documentação do Obsidian
│   ├── Idiomas/
│   │   └── Inglês/
│   │       └── Caderno-de-Estudos/  # Material didático migrado
│   └── OpenClaw-Docs/         # Documentação oficial
├── Memory/
│   ├── OpenClaw-Memory-Log/   # Log filosófico da IA
│   ├── daily/                 # Logs de sessão
│   └── MEMORY.md              # Memórias permanentes
└── Projects/
    └── Setup-Multiagentes/    # Setup otimizado
```

**Migração Completa:**
- Arquivos de `E:\class-english\*.md` → `Knowledge\Idiomas\Ingles\Caderno-de-Estudos\`
- Logs da Docker → `Memory/OpenClaw-Memory-Log\`
- Memórias de sessão → `memory\daily\` → distilados para `MEMORY.md`
