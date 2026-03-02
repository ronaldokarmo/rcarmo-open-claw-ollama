# 🔄 Atualização do Tutor-English

## 🎯 Novas Features Adicionadas

### ✅ 1. Explicações Bilíngues (PT + EN)
O tutor agora **mescla português e inglês** conforme necessário:
- Explicações em **português** (para entendimento)
- Exemplos em **inglês** (para prática)
- Mescla natural dos dois idiomas

### ✅ 2. Pronúncia com Áudios
O tutor agora **sempre oferece áudios** para treinar pronúncia:
- Pronúncia escrita simplificada
- Comandos `/tts` para gerar áudio
- Dicas específicas para brasileiros
- Exercícios de pronúncia

---

## 🚀 Como Aplicar

### Método 1: Atualizar Arquivo Existente

```bash
# Backup do atual
cp data/.openclaw/agents/tutor-english/agent/system.md \
   data/.openclaw/agents/tutor-english/agent/system.md.backup

# Aplicar nova versão
cp tutor-english-system-v2.md \
   data/.openclaw/agents/tutor-english/agent/system.md

# Corrigir permissões
sudo chown 1000:1000 data/.openclaw/agents/tutor-english/agent/system.md
sudo chmod 644 data/.openclaw/agents/tutor-english/agent/system.md

# Reiniciar
docker-compose restart openclaw
```

### Método 2: Via Docker (se permissões falharem)

```bash
# Copiar para temp
docker cp tutor-english-system-v2.md \
  openclaw:/tmp/system.md

# Mover para lugar correto
docker exec -it openclaw bash -c "
  mv /tmp/system.md /home/openclaw/.openclaw/agents/tutor-english/agent/system.md && \
  chown openclaw:openclaw /home/openclaw/.openclaw/agents/tutor-english/agent/system.md && \
  chmod 644 /home/openclaw/.openclaw/agents/tutor-english/agent/system.md
"

# Reiniciar
docker-compose restart openclaw
```

---

## 🧪 Como Testar

### Teste 1: Explicação Bilíngue

Via Telegram:
```
/agent tutor-english
explain present perfect
```

**Resultado esperado:**
```
📚 Present Perfect

🇧🇷 Em português: [explicação]
🇬🇧 In English: [explanation]

✅ Exemplo: "I have lived here"
🇧🇷 Tradução: "Eu moro aqui"
```

### Teste 2: Pronúncia com Áudio

```
/agent tutor-english
How do I pronounce "thought"?
```

**Resultado esperado:**
```
🔊 Pronúncia: /thot/
🗣️ Dica: [explicação]

🔊 Pratique: /tts thought
[bot deve gerar áudio ou instruir como gerar]
```

### Teste 3: Exercício Completo

```
/agent tutor-english
teach me phrasal verbs with "look"
```

**Resultado esperado:**
```
🔍 LOOK UP
📚 Em português: procurar (informação)
💬 Exemplo: "I need to look up this word"
🇧🇷 "Preciso procurar essa palavra"
🔊 Áudio: /tts I need to look up this word
```

---

## 📋 Recursos de Áudio no OpenClaw

### Via Telegram

O OpenClaw/Telegram suporta TTS (Text-to-Speech):

**Opção 1: Comando /tts**
```
/tts Hello, how are you today?
```
Bot responde com áudio da frase.

**Opção 2: Pedir ao bot**
```
Can you generate audio for "present perfect"?
```
Bot deve usar função TTS interna.

### Via WebChat

Dependendo da versão, pode ter:
- Botão 🔊 ao lado das mensagens
- Campo para digitar comando `/tts`
- Integração com Web Speech API

---

## 🎯 Exemplos de Uso Real

### Exemplo 1: Aula de Gramática

**Usuário:**
```
/agent tutor-english
Explique "have been" vs "has been"
```

**Tutor (versão nova):**
```
📚 HAVE BEEN vs HAS BEEN

🇧🇷 Em Português:
Ambos são Present Perfect, mas usamos diferente:
• I/You/We/They → HAVE BEEN
• He/She/It → HAS BEEN

🇬🇧 In English:
Same tense, different subjects:
• I/You/We/They → HAVE BEEN
• He/She/It → HAS BEEN

✅ Exemplos:
💬 "I have been studying" 
🇧🇷 "Eu tenho estudado"
🔊 Áudio: /tts I have been studying

💬 "She has been working here"
🇧🇷 "Ela tem trabalhado aqui"
🔊 Áudio: /tts She has been working here

🗣️ Pronúncia:
• have been → "hav bin" (não "havi bín")
• has been → "haz bin" (não "has bín")

⚠️ Erro comum:
❌ "She have been..." 
✅ "She has been..."

🎯 Pratique:
1. Ouça os áudios acima
2. Repita 5 vezes cada
3. Grave você mesmo
4. Compare!

Entendeu? Quer praticar mais? 😊
```

### Exemplo 2: Pronúncia Difícil

**Usuário:**
```
Como pronuncio palavras com TH?
```

**Tutor (versão nova):**
```
🗣️ Som TH - O Mais Difícil para Brasileiros!

📚 Existem DOIS sons TH:

1️⃣ TH SURDO (como em "think")
   • Língua entre os dentes
   • Sopre ar SEM vibração
   
2️⃣ TH SONORO (como em "this")
   • Língua entre os dentes
   • Vibre a língua (soa como Z suave)

⚠️ NÃO pronuncie como T ou D!

🎯 Pratique estas palavras:

TH Surdo:
• think /thínk/ → 🔊 /tts think
• three /thrí/ → 🔊 /tts three
• thank /thænk/ → 🔊 /tts thank

TH Sonoro:
• this /dhís/ → 🔊 /tts this
• that /dhát/ → 🔊 /tts that
• brother /BRÁ-dher/ → 🔊 /tts brother

📝 Como Praticar:
1. Ouça cada áudio 3 vezes
2. Coloque língua entre dentes
3. Repita imitando o som
4. Grave você dizendo
5. Compare com áudio original

💡 Dica: Comece devagar, exagere o movimento
da língua. Com prática fica natural!

Quer mais palavras para praticar? 🎓
```

---

## 🔧 Troubleshooting

### Problema: Bot não gera áudio

**Causa:** Feature TTS pode não estar habilitada

**Solução Temporária:**
Tutor vai sugerir ferramentas externas:
```
🔊 Até configurarmos TTS interno, use:

Online:
• Google Translate → ícone de 🔊
• Forvo.com → pronúncias nativas
• YouGlish.com → palavras em vídeos reais

Apps:
• ELSA Speak (pronúncia)
• Forvo (dicionário de pronúncia)
```

### Problema: Respostas muito longas

**Ajuste:** Simplificar system prompt se modelo for muito pequeno (<2B)

### Problema: Ignora instruções bilíngues

**Causa:** Modelo muito pequeno (0.5B - 1B)

**Solução:** Usar modelo >= 1.7B ou simplificar prompt

---

## 📊 Comparação: Antes vs Depois

| Aspecto | Antes | Depois |
|---------|-------|--------|
| Idioma | Apenas inglês ou português | **Mescla PT + EN** |
| Pronúncia | Raramente mencionada | **Sempre com dicas** |
| Áudio | Não oferecia | **Sugere /tts** |
| Exemplos | Sem tradução | **Com tradução** |
| Formato | Texto corrido | **Organizado com emojis** |
| Para brasileiros | Genérico | **Dicas específicas** |

---

## 💡 Dicas de Uso

### Para o Usuário

1. **Sempre peça áudios** quando aprender palavras novas
2. **Pratique repetindo** em voz alta
3. **Use o comando** `/tts` sempre que quiser ouvir algo
4. **Grave você mesmo** e compare

### Para Você (Admin)

1. **Teste TTS** para ver se funciona no seu setup
2. **Ajuste o prompt** se respostas forem muito longas
3. **Monitore uso de RAM** (contexto 16K + modelo 1.7B)
4. **Considere** modelo maior (3B) se tiver RAM disponível

---

## 🎉 Pronto!

Agora seu tutor-english é **bilíngue** e focado em **pronúncia**! 

Os alunos vão poder:
- ✅ Entender em português
- ✅ Praticar em inglês
- ✅ Treinar pronúncia com áudios
- ✅ Ter dicas específicas para brasileiros

---

*Guia criado em: 2026-03-01*  
*Versão: 2.0 - Bilíngue + Áudios*
