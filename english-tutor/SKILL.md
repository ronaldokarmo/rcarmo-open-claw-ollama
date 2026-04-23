# English Tutor Skill

## 🎯 Purpose

Skill de tutor de inglês para fornecer **avaliação completa em 5 pilares**: Pronúncia, Naturalidade, Vocabulário, Compreensão e Gramática.

## 🚀 Setup

### Instalação no OpenClaw

```bash
# Adicionar skill à pasta de triggers
mkdir -p triggers/english-tutor
cp english-tutor/SKILL.md triggers/english-tutor/
cp english-tutor/system.md triggers/english-tutor/

# Reiniciar o OpenClaw
openclaw restart
```

### Triggers Disponíveis

| Trigger | Descrição |
|---------|-----------|
| `!english` | Ativa tutor de inglês |
| `!ingles` | Alias em português |

### Metadados

```json
{
  "name": "english-tutor",
  "version": "1.0.0",
  "description": "Tutor de inglês com avaliação em 5 pilares",
  "triggers": ["!english", "!ingles"],
  "model": "groq",
  "auto_detect": true
}
```

## 📝 Como Usar

```
!english
[Áudio ou texto em inglês]
```

### O que acontece:

1. **Transcrição** (se for áudio)
2. **Avaliação nos 5 pilares:**
   - ✅ Pronúncia (para áudio)
   - ✅ Naturalidade (para áudio)
   - ✅ Vocabulário (todo conteúdo)
   - ✅ Compreensão (todo conteúdo)
   - ✅ Gramática (todo conteúdo)
3. **Feedback detalhado** com correções e explicações
4. **Sugestões de melhoria** personalizadas

## 🔄 Fluxo Completo

```
1. User envia: "!english" + conteúdo
2. Sistema detecta linguagem (inglês)
3. Transcreve áudio → texto (se aplicável)
4. Avalia em 5 pilares
5. Gera feedback estruturado
6. Sugerir próximos passos
```

## 🎯 Diferenciais

- **Avaliação completa** em 5 pilares (não apenas gramática)
- **Transcrição automática** de áudio
- **Feedback acionável** com exemplos
- **Contexto técnico** para Test Engineer
- **Progress tracking** sugerido

---

*Esta skill foi criada para o ecossistema de agentes do OpenClaw, integrado com a memory-wiki para persistência de aprendizado.*
