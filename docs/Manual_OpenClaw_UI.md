# 🦞 Guia Prático: Dominando o OpenClaw Control UI

Bem-vindo ao seu painel de controle mestre! O **OpenClaw** não é apenas um chat isolado; ele é um orquestrador de Múltiplos Agentes. Este guia vai te ensinar a extrair todo o poder dos menus e recursos que você vê na barra lateral.

---

## 💬 1. CHAT & SESSÕES (Onde a mágica acontece)

### Menu `Chat`
A interface principal, idêntica as ferramentas de IA de mercado.
- **Seletor de Sessão (Dropdown Superior Esquerdo):** O OpenClaw atua como a ponte de conexões simultâneas. O menu dropdown permite que você transite entre:
  - `main`: O seu painel de chat de testes no navegador.
  - `Telegram`: As conversas diretas que estão acontecendo lá no app do seu celular.
  - Comandos dinâmicos (sessões efêmeras geradas via barra `/`).
- **Seletor de Modelos (Dropdown Central):** Permite forçar um modelo específico na sessão. Para operações normais, deixe como `Adaptive` ou `Main` para o Roteador escolher, ou defina estaticamente (ex: `Qwen Local`) se quiser forçar o roteamento.
- **Aviso de Contexto Laranja (X% context used):** O OpenClaw te avisa quando a conversa está ficando "pesada" para a memória RAM (VRAM) do modelo ativo. Use o comando `/clear` para resetar a amnésia e começar um assunto novo se travar.

### Menu `Sessions`
Como vimos anteriormente, cada conversa tem uma "memória" física guardada aqui (histórico). Se uma sessão se comportar mal, bugar com contexto excessivo ou você simplesmente quiser organizar a casa: vá em *Sessions* e clique na lixeira para deletá-las.

---

## 🧠 2. AGENTS & SKILLS (Seus Parceiros)

### Menu `Agents`
Você não tem um só robô, você tem uma equipe!
Nessa aba, você visualiza os cérebros cadastrados:
1. **Atom (Main):** O coordenador-geral.
2. **Tutor de Inglês / Engenheiro IoT / Prompt Architect:** Especialistas.
> *Como usar:* Você não precisa invocar os nomes deles no chat. O OpenClaw escuta suas mensagens de texto ou voz e, se identificar a palavra *"inglês"*, passa o controle na hora para o Tutor de Inglês sem que você perceba a troca.

### Menu `Skills`
As "Mãos" dos agentes. Uma IA sozinha só gera texto. Uma IA com Skills consegue executar código.
- Nossos agentes possuem a Skill de **Pesquisa no Obsidian** (`grep`) e de **Escrita no Obsidian** (`bash / cat`). Na aba de *Skills*, você pode recarregar (Reload) essas habilidades se alterar o código-fonte delas.

---

## ⚙️ 3. SETTINGS & CONTROL (Sala de Máquinas)

### Menu `Config`
A representação visual do famoso arquivo `openclaw.json`. 
Por aqui, você pode alterar Chaves de API (Groq, Moonshot) ou a lista de fallbacks (Se o Kimi Cloud cair, ative o Llama Local). Toda alteração estrutural mais densa passa por aqui.

### Menu `Logs`
A sua melhor ferramenta para "debug" (achar falhas). Quando você pedir algo complexo ("escreva no Obsidian") e o robô falhar calado, corra para a aba Logs. O terminal vai te dizer exatamente em vermelho se "A pasta não existia" ou se "O comando bash foi bloqueado".

### Menu `Channels`
Onde configuramos os "ouvidos" externos do bot. Como o **Telegram**. O OpenClaw foi feito de uma forma modular, significando que no futuro você poderia adicionar canais do Discord ou WhatsApp, e todos desaguariam nessa mesma UI!

---

## 💡 Dicas de Ouro (Atalhos Úteis)

1. **O Comando `/clear`:** A tecla mais poderosa do sistema. Zera o cache imediato da sessão em aberto quando a IA "ficar confusa" sobre algo que foi dito antes.
2. **Botão Vermelho (Standby/Restart):** No canto superior direito da UI. Aperte-o para forçar uma limpeza ou recarregar as configurações de JSON quando fizer edições em arquivos físicos e quiser refletir na mesma hora.
3. **Hardware Limit (`Adaptive` mode):** Confie na nuvem para tarefas conversacionais cotidianas (para poupar o uso constante e a geração de calor da sua Placa de Vídeo - RTX 4060). Use Modelos Locais via painel apenas quando o código enviado exigir confidencialidade total e não puder sair do seu PC.
