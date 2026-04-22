# Guia de Trabalho: Obsidian + OpenClaw

Agora que o seu Obsidian Vault (`E:\obsidian\ai-data`) está espelhado e indexado dentro do OpenClaw, o agente não é mais apenas um modelo estático isolado — ele tem acesso ao seu "segundo cérebro". 

Para extrair o máximo de valor dessa integração, é importante entender como o agente lê seus dados e como estruturá-los para um consumo inteligente.

---

## 1. Como a IA interage com o Obsidian

No momento, o OpenClaw interage com o seu vault de duas formas trabalhando em conjunto:

1. **Ativa ("Modo Caçador" - Nossa Skill):** Quando você dá um comando explícito (ex: *"busque nas minhas notas"*), a skill `obsidian-vault-search` usa comandos de terminal hiper-rápidos (`grep`, `find`) para varrer o cofre inteiro atrás de palavras-chave exatas e trazer o conteúdo do Markdown diretamente para o contexto.
2. **Passiva ("Modo Memória" - Plugin Nativo):** O plugin `memory-wiki` (que ativamos) lê o vault e injeta contexto quando necessário nas conversas do dia a dia, compreendendo os `[[Wikilinks]]` do Obsidian.

---

## 2. A Estrutura Ideal do Cofre

O agente compreende o mundo através de pastas e arquivos Markdown. A estrutura que você tem é perfeita, mas aqui está como você deve preenchê-la:

### 📁 `Knowledge/` (Conhecimento Frio)
**O que é:** Sua biblioteca de longo prazo. Manuais, documentações de APIs, conceitos que você aprendeu, trechos de código que você sempre esquece como fazer.
**Como a IA usa:** 
* Ao ser questionada sobre um termo técnico, ela buscará aqui para não "alucinar" (inventar coisas).
* *Exemplo de uso:* Salve um arquivo `OpenClaw Docker Setup.md` com comandos exatos. A IA lerá de lá antes de te responder da próxima vez.

### 📁 `Memory/` (Contexto Quente e Regras)
**O que é:** O manual de instruções de *como a IA deve tratar você*.
**Como a IA usa:** 
* Esta é a pasta mais poderosa para agentes. Coloque aqui arquivos com regras de programação, suas preferências de linguagem (ex: *"Sempre me responda em português neutro, sem gírias"*), ou regras de sistema.
* *Exemplo de uso:* Se você tiver um arquivo `Diretrizes Python.md` dizendo `"Sempre use Type Hints e docstrings no padrão Google"`, você pode dizer ao agente: *"Crie um script Python para ler CSV. Siga as diretrizes de Python da minha memória."*

### 📁 `Projects/` (Contexto Ativo)
**O que é:** O trabalho do momento. Tudo que tem início, meio e fim.
**Como a IA usa:**
* Útil para injetar um contexto massivo de uma vez só. 
* *Exemplo de uso:* Crie um `Plano-App-Fincanceiro.md` com todos os requisitos. No Telegram, basta dizer: *"Leia as notas do meu Projeto App Financeiro e gere o código do backend para mim."*

---

## 3. "Escrevendo para a IA" (AI-Friendly Markdown)

A IA consegue ler qualquer texto, mas ela extrai respostas muito mais rápido se você formatar suas notas pensando nela. No Obsidian, use e abuse de:

> [!TIP]
> **Use Cabeçalhos (Headings):**
> A IA usa `#`, `##` e `###` para entender a hierarquia do documento. Se você tiver um `## Comandos de Reinício`, a IA saberá ir direto ali em vez de ler o texto inteiro.

> [!TIP]
> **Listas com Marcadores e Tabelas:**
> Modelos de linguagem amam tabelas e `- bullets`. Eles quebram a complexidade. Evite blocos de texto contínuos maiores que 3 parágrafos.

> [!TIP]
> **Blocos de Código Tagueados:**
> Ao salvar exemplos de código ou saídas do terminal, **sempre** coloque a linguagem correta nas crases (ex: ` ```bash`, ` ```python `). Isso ajuda o parser do agente a extrair apenas o código quando for te devolver uma resposta.

---

## 4. Padrões de Prompt (Como pedir coisas)

Com a integração pronta, você ganha "superpoderes" nos seus prompts. Tente estas abordagens:

**A. Consulta Cega (RAG - Retrieval-Augmented Generation)**
> *"O que eu anotei sobre [Assunto] na minha base de conhecimento?"*
> *"Consulte meu vault e veja quais são as diretrizes de segurança de servidores que eu salvei."*

**B. Contexto Injetado para Criação**
> *"Estou no projeto X. Leia a nota correspondente no diretório Projects e, com base nela, escreva a primeira página HTML."*

**C. Auditoria e Revisão**
> *"Este é um e-mail que vou mandar para o chefe. Leia minhas notas em 'Memory/Preferências de Comunicação' e reescreva o e-mail no tom que eu defini lá."*

---

## 5. Próximos Passos e Evolução

Atualmente, o fluxo é **One-Way (Do Obsidian para o OpenClaw)**. Você anota no Obsidian do seu Windows (ambiente confortável) e o OpenClaw lê no terminal (container Docker). 

**Para o Futuro:**
Se você quiser que o OpenClaw crie notas para você (ex: *"resuma essa nossa conversa e salve no Obsidian no projeto Y"*), precisaremos atualizar a nossa `SKILL.md` para suportar comandos de escrita (`echo`, `tee` ou ferramentas nativas de file write do agente), ou configurar ferramentas de Workspace. No momento, mantivemos a leitura por motivos de segurança, garantindo que o agente não modifique sem querer o seu cofre.
