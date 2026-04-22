# Limpeza Base Obsidian (Remoção de Nós Órfãos)

## 🔍 O Diagnóstico

Fiz um scan nos diretórios raiz do seu Obsidian (em `Knowledge`, `Memory` e `Projects`) e descobri exatamente do que você está falando.

Quando você montou o ambiente inicialmente, você provavelmente digitou nomes no Obsidian esquecendo que o aplicativo já põe o `.md` sozinho, o que gerou arquivos com a extensão `.md.md`. 

Além disso, eles são arquivos de testes preliminares, a maioria está vazio (0 bytes) e os soltos contêm informações agora obsoletas e que já migramos com muito mais força para os Manuais nas novas pastas.

### 🗑️ Lista de Remoção Proposta

Vou limpar os seguintes arquivos soltos:

#### [DELETE] `Knowledge/Obsidian.md.md`
- **Motivo:** Arquivo fantasma (testes com 0 bytes).

#### [DELETE] `Knowledge/OpenClaw.md.md`
- **Motivo:** Continha apenas 5 linhas dizendo que o OpenClaw era o agente principal (já temos a Bíblia deles em `OpenClaw-Docs/AGENTS.md`).

#### [DELETE] `Memory/Comandos úteis.md.md`
- **Motivo:** Fantasma (0 bytes).

#### [DELETE] `Memory/Preferências.md.md`
- **Motivo:** Texto pequeno com 4 regras ("Usar português, ser pragmático..."). Já resolvemos isso num nível sistêmico nas Skills (`obsidian-vault-writer`).

#### [DELETE] `Memory/Setup.md.md`
- **Motivo:** Continha aquele rascunho obsoleto sobre *Syncthing*. Sabemos que abandonamos isso pelo *Volume Mount* que é muito superior e que já documentamos em `Projects/Setup-Multiagentes-Otimizado.md`.

#### [DELETE] `Projects/OpenClaw+Obsidian.md.md`
- **Motivo:** Fantasma (0 bytes).

---

## ⚡ Consequência
Após a exclusão:
1. Seu cofre perderá todo o "ruído" visual.
2. Seu gráfico de nós (Graph View) ficará lindo, focado apenas nas pastas ricas e arquitetônicas que criamos hoje, sem pontinhos desconectados flutuando.

> [!CAUTION]
> **Aprovação Necessária:** Como estou apagando arquivos físicos do seu HD, preciso do seu "Vá em frente" para eu executar a lixeira via terminal!
