# 🚀 OpenClaw Docker - Multiagente & Local LLM

Este projeto fornece um ambiente Docker completo e otimizado para rodar o **OpenClaw Gateway** integrado com **Ollama** (modelos locais) e suporte nativo a múltiplos agentes especializados.

## 🌟 Funcionalidades

- **Múltiplos Agentes**: Configuração pronta para uso com 3 agentes:
  - `main`: Coordenador e roteador inteligente.
  - `tutor-english`: Especialista em ensino de inglês.
  - `tutor-iot`: Especialista em Arduino, ESP32 e eletrônica.
- **Modelos Locais**: Integração profunda com Ollama para privacidade e economia.
- **WSL2 Otimizado**: Scripts inclusos para garantir compatibilidade com systemd no Windows.
- **Segurança**: Verificação automática de permissões e isolamento de workspaces.
- **Proxy Integrado**: Nginx pré-configurado para exposição segura do gateway.

---

## 🏗️ Arquitetura

```mermaid
graph TD
    User([Usuário]) -->|Telegram / Web| Nginx[Nginx Proxy]
    Nginx -->|Port 18790| OC[OpenClaw Gateway]
    OC -->|Roteamento| Agents{Agentes}
    Agents -->|English Specialist| TE[Tutor English]
    Agents -->|IoT Specialist| TI[Tutor IoT]
    OC -->|API| Ollama[Ollama LLM]
    Ollama -->|GPU Accel| GPU((NVIDIA GPU))
```

---

## 🚀 Como Iniciar

### 1. Pré-requisitos
- Docker & Docker Compose
- Windows com WSL2 (recomendado) ou Linux
- GPU NVIDIA (opcional, para melhor performance)

### 2. Configuração Automática (Recomendado)
Execute o script de setup para criar toda a estrutura de agentes e permissões:

```bash
chmod +x quick-setup-multiagent.sh
./quick-setup-multiagent.sh
```

### 3. Variáveis de Ambiente
Copie o arquivo de exemplo e configure suas chaves:

```bash
cp .env.example .env  # Se não existir
nano .env
```

**Configurações críticas no `.env`:**
- `OPENCLAW_GATEWAY_TOKEN`: Sua chave de acesso.
- `TELEGRAM_BOT_TOKEN`: Token do seu bot.

### 4. Iniciar containers
```bash
docker-compose up -d
```
---

Documento de restauração criado com sucesso! 📄

## **Guia Completo de Restauração Criado**

**Arquivo**: `GUIDA-RESTAURACAO-BACKUPS.md`
**Localização**: `/home/openclaw/.openclaw/workspace/`

## **Conteúdo do Guia:**

### 📋 **Estrutura Completa**
- ✅ **Visão Geral** - Entendimento do processo
- ✅ **Backup Disponíveis** - Detalhes dos arquivos de backup
- ✅ **Preparação** - Verificação de espaço e preparação do ambiente
- ✅ **Restauração OpenClaw** - Passo a passo completo
- ✅ **Restauração Docker** - Configuração específica
- ✅ **Configuração Pós-Restauração** - Ajustes finais
- ✅ **Verificação Final** - Checklist completo
- ✅ **Troubleshooting** - Soluções para problemas comuns

### 🔧 **Recursos Práticos**
- **Checklists** - Verificação passo a passo
- **Comandos Exatos** - Copy-paste dos comandos necessários
- **Tabela de Verificação** - Status esperado para cada item
- **Soluções de Problemas** - Respostas para erros comuns

### 🎯 **Destaques do Guia**
1. **Segurança** - Inclui medidas de permissões críticas
2. **Completude** - Abrange OpenClaw e Docker
3. **Praticidade** - Comandos prontos para executar
4. **Prevenção** - Backup pré-restauração opcional
5. **Diagnóstico** - Comandos de verificação completa

O guia está agora disponível em seu workspace e pode ser acessado sempre que precisar restaurar seus backups!

---

## 🤖 Uso dos Agentes

O sistema utiliza roteamento automático baseado em intenção e palavras-chave.

- **Geral**: "Olá, como você está?" (Respondido pelo `main`)
- **Inglês**: "Como digo 'alcançar' em inglês?" (Delegado ao `tutor-english`)
- **IoT**: "Como configurar o ESP32 para ler sensores?" (Delegado ao `tutor-iot`)

---

## 🛠️ Comandos Úteis

| Comando | Descrição |
|---------|-----------|
| `docker-compose logs -f openclaw` | Ver logs do gateway em tempo real |
| `./fix-permissions.sh` | Corrigir problemas de escrita nos volumes |
| `docker exec -it openclaw openclaw doctor --fix` | Reparar configuração corrompida |
| `docker-compose restart openclaw` | Reiniciar para aplicar mudanças no prompt |

---

## 🧠 Otimização de Memória (RAM)

O projeto está configurado no `docker-compose.yml` para rodar em sistemas com **11GB+ de RAM/VRAM**:
- `OLLAMA_MAX_LOADED_MODELS=1`: Apenas um modelo carregado por vez.
- `OLLAMA_NUM_PARALLEL=1`: Evita picos de memória.
- Limite de 6GB via Docker constraints.

---

## 📄 Licença

Este projeto é uma implementação customizada baseada no [OpenClaw](https://github.com/openclaw/openclaw).

---
