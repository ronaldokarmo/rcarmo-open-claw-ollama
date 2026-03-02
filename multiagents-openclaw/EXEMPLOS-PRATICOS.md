# 💡 Exemplos Práticos - Multiagentes OpenClaw

## 📚 Índice
1. [Conversas com Tutor de Inglês](#tutor-inglês)
2. [Conversas com Tutor de IoT](#tutor-iot)
3. [Transições entre Agentes](#transições)
4. [Menções Diretas](#menções-diretas)
5. [Casos de Uso Avançados](#avançado)

---

## 🇬🇧 Tutor de Inglês

### Exemplo 1: Correção Gramatical

**Usuário:**
```
Can you check this sentence?
"I have went to school yesterday"
```

**Tutor English:**
```
📝 Vou corrigir para você!

❌ Erro: "I have went to school yesterday"
✅ Correto: "I went to school yesterday"

📚 Explicação:
Quando usamos um tempo específico no passado (como "yesterday"), 
devemos usar o Simple Past, não o Present Perfect.

Regra:
• Present Perfect: ações sem tempo específico
  → "I have been to Paris" (em algum momento da vida)
  
• Simple Past: ações com tempo específico
  → "I went to Paris last year" (tempo definido)

Outros exemplos corretos:
✅ "I went to school today"
✅ "I have been to that school before"
✅ "I went there on Monday"

Ficou claro? 😊
```

---

### Exemplo 2: Vocabulário

**Usuário:**
```
What's the difference between "travel", "trip" and "journey"?
```

**Tutor English:**
```
📖 Ótima pergunta! Vou explicar as diferenças:

🌍 TRAVEL (substantivo/verbo)
Significado: O ato de viajar em geral
Uso: Mais abstrato, o conceito de viajar
Exemplos:
• "I love to travel" (Eu amo viajar)
• "Business travel is tiring" (Viagens de negócios são cansativas)

✈️ TRIP (substantivo)
Significado: Uma viagem específica (ida e volta)
Uso: Viagem concreta com início e fim
Exemplos:
• "I'm taking a trip to Japan next month"
• "It was a short trip" (Foi uma viagem curta)
• "Business trip" / "Road trip"

🚶 JOURNEY (substantivo)
Significado: A jornada/trajeto de um lugar a outro
Uso: Foco no processo da viagem, não no destino
Exemplos:
• "The journey took 5 hours" (O trajeto levou 5h)
• "Life is a journey" (A vida é uma jornada)
• Mais formal/literário

📝 Resumo:
├─ Travel = conceito geral de viajar
├─ Trip = viagem específica (ida e volta)
└─ Journey = o trajeto/processo da viagem

Dica: Para viagens curtas ou de férias, use "trip".
Para deslocamentos longos ou metafóricos, use "journey".

Precisa de mais exemplos? 🤓
```

---

### Exemplo 3: Phrasal Verbs

**Usuário:**
```
I'm confused about "look", "look up", "look for", "look after"...
```

**Tutor English:**
```
🔍 Phrasal Verbs com LOOK - Guia Completo!

1️⃣ LOOK (olhar - simples)
   "Look at the board" → Olhe para o quadro

2️⃣ LOOK UP (procurar informação / olhar para cima)
   📱 "I need to look up this word" 
      → Preciso procurar essa palavra
   ⬆️ "Look up at the sky"
      → Olhe para cima, para o céu

3️⃣ LOOK FOR (procurar algo/alguém)
   🔎 "I'm looking for my keys"
      → Estou procurando minhas chaves
   💼 "She's looking for a job"
      → Ela está procurando emprego

4️⃣ LOOK AFTER (cuidar de)
   👶 "Can you look after my baby?"
      → Você pode cuidar do meu bebê?
   🐕 "I look after my neighbor's dog"
      → Eu cuido do cachorro do vizinho

5️⃣ LOOK FORWARD TO (ansiar por)
   🎉 "I'm looking forward to the party"
      → Estou ansioso pela festa
   ⚠️ Sempre seguido de -ING ou substantivo!

6️⃣ LOOK INTO (investigar)
   🔬 "The police are looking into the case"
      → A polícia está investigando o caso

📊 Tabela Resumo:
┌─────────────────┬──────────────────┬────────────────┐
│ Phrasal Verb    │ Tradução         │ Exemplo        │
├─────────────────┼──────────────────┼────────────────┤
│ look up         │ procurar (info)  │ dictionary     │
│ look for        │ procurar (físico)│ keys, job      │
│ look after      │ cuidar de        │ baby, pet      │
│ look forward to │ ansiar por       │ vacation       │
│ look into       │ investigar       │ problem        │
└─────────────────┴──────────────────┴────────────────┘

✍️ Exercício Rápido:
Complete:
1. I'm _______ my phone. (procurando)
2. Can you _______ my cat while I'm away? (cuidar)
3. I _______ seeing you soon! (ansioso)

Respostas: 1) looking for, 2) look after, 3) look forward to

Quer praticar mais? 💪
```

---

## 🤖 Tutor de IoT

### Exemplo 4: Conexão de Sensor

**Usuário:**
```
Como faço para ler temperatura com DHT22 no ESP32?
```

**Tutor IoT:**
```
🌡️ Leitura de Temperatura com DHT22 no ESP32

Vou te mostrar o passo a passo completo!

📦 **1. Componentes Necessários**
├─ ESP32 DevKit
├─ Sensor DHT22
├─ Resistor 10kΩ (pull-up)
├─ Protoboard
└─ Jumpers

🔌 **2. Conexões**
```
DHT22          ESP32
┌──────────┐   ┌──────────┐
│ VCC (1)  │───│ 3.3V     │
│ DATA (2) │───│ GPIO4    │ ← + pull-up 10kΩ para VCC
│ NC (3)   │   │          │ (não conectar)
│ GND (4)  │───│ GND      │
└──────────┘   └──────────┘

   VCC ────┬──── DHT22 VCC
           │
         [10kΩ]  ← Pull-up resistor
           │
   GPIO4 ──┴──── DHT22 DATA
   
   GND ───────── DHT22 GND
```

⚠️ **IMPORTANTE**: O resistor pull-up é OBRIGATÓRIO!

💻 **3. Código Arduino**

```cpp
// ========================================
// Leitura DHT22 com ESP32
// ========================================
#include <DHT.h>

// Definições
#define DHTPIN 4        // Pino de dados conectado ao GPIO4
#define DHTTYPE DHT22   // Tipo do sensor (DHT11 ou DHT22)

// Inicializa o sensor
DHT dht(DHTPIN, DHTTYPE);

void setup() {
  // Inicia comunicação serial
  Serial.begin(115200);
  Serial.println("Inicializando DHT22...");
  
  // Inicia o sensor
  dht.begin();
  
  // Aguarda estabilização
  delay(2000);
  Serial.println("DHT22 pronto!");
}

void loop() {
  // Lê temperatura (em Celsius)
  float temperatura = dht.readTemperature();
  
  // Lê umidade (em %)
  float umidade = dht.readHumidity();
  
  // Verifica se a leitura foi bem-sucedida
  if (isnan(temperatura) || isnan(umidade)) {
    Serial.println("❌ Erro ao ler o sensor!");
    Serial.println("Verifique as conexões.");
    delay(2000);
    return;  // Sai da função e tenta novamente
  }
  
  // Exibe os valores no Serial Monitor
  Serial.println("─────────────────────");
  Serial.print("🌡️  Temperatura: ");
  Serial.print(temperatura);
  Serial.println(" °C");
  
  Serial.print("💧 Umidade: ");
  Serial.print(umidade);
  Serial.println(" %");
  Serial.println("─────────────────────\n");
  
  // Aguarda 2 segundos antes da próxima leitura
  // (DHT22 tem taxa máxima de 0.5Hz = 1 leitura a cada 2s)
  delay(2000);
}
```

📚 **4. Instalação da Biblioteca**

No Arduino IDE:
1. Abra: **Sketch → Include Library → Manage Libraries**
2. Busque: **"DHT sensor library"**
3. Instale: **DHT sensor library by Adafruit**
4. Instale também: **Adafruit Unified Sensor** (dependência)

🔧 **5. Troubleshooting**

❌ "Erro ao ler o sensor":
   ✅ Verifique se o resistor pull-up está conectado
   ✅ Confirme que o pino DATA está no GPIO4
   ✅ Aguarde 2 segundos entre leituras

❌ Valores sempre NaN:
   ✅ Verifique alimentação (3.3V ou 5V)
   ✅ Teste com outro sensor (pode estar queimado)

❌ Compilação falha:
   ✅ Instale as bibliotecas mencionadas
   ✅ Selecione a placa: Tools → Board → ESP32 Dev Module

📈 **6. Melhorias Possíveis**

• **LCD Display**: Mostrar valores em display
• **WiFi**: Enviar dados para servidor/ThingSpeak
• **SD Card**: Gravar histórico de temperaturas
• **Alertas**: LED/buzzer quando temperatura > limite

💡 **Dicas:**
├─ DHT22 é mais preciso que DHT11 (±0.5°C vs ±2°C)
├─ Funciona de -40°C a 80°C
├─ Evite exposição direta ao sol
└─ Tempo de resposta: 2 segundos

Precisa de ajuda com alguma melhoria específica? 🚀
```

---

### Exemplo 5: MQTT com ESP32

**Usuário:**
```
Quero enviar dados do sensor para broker MQTT. Como faz?
```

**Tutor IoT:**
```
📡 ESP32 + DHT22 + MQTT - Projeto Completo!

Vou te mostrar como enviar dados do DHT22 via MQTT.

🏗️ **Arquitetura do Sistema**

```
┌─────────┐  WiFi   ┌──────────┐  MQTT   ┌────────────┐
│  DHT22  │────────▶│  ESP32   │────────▶│ Broker     │
│ Sensor  │         │          │         │ (Mosquitto)│
└─────────┘         └──────────┘         └─────┬──────┘
                                               │
                                               ▼
                                         ┌──────────┐
                                         │ Cliente  │
                                         │ (App)    │
                                         └──────────┘
```

📚 **1. Bibliotecas Necessárias**

```cpp
#include <WiFi.h>           // WiFi do ESP32
#include <PubSubClient.h>   // Cliente MQTT
#include <DHT.h>            // Sensor DHT22
```

💻 **2. Código Completo**

```cpp
// ========================================
// ESP32 + DHT22 + MQTT
// ========================================
#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>

// ─────────────────────────────────
// Configurações WiFi
// ─────────────────────────────────
const char* ssid = "SUA_REDE_WIFI";
const char* password = "SUA_SENHA_WIFI";

// ─────────────────────────────────
// Configurações MQTT
// ─────────────────────────────────
const char* mqtt_server = "broker.hivemq.com";  // Broker público
const int mqtt_port = 1883;
const char* mqtt_user = "";          // Deixe vazio se não precisar
const char* mqtt_password = "";
const char* mqtt_client_id = "ESP32_DHT22_001";

// Tópicos MQTT
const char* topic_temp = "casa/quarto/temperatura";
const char* topic_umid = "casa/quarto/umidade";
const char* topic_status = "casa/quarto/status";

// ─────────────────────────────────
// Configurações DHT22
// ─────────────────────────────────
#define DHTPIN 4
#define DHTTYPE DHT22

// ─────────────────────────────────
// Objetos
// ─────────────────────────────────
WiFiClient espClient;
PubSubClient client(espClient);
DHT dht(DHTPIN, DHTTYPE);

// ─────────────────────────────────
// Variáveis
// ─────────────────────────────────
unsigned long lastMsg = 0;
const long interval = 5000;  // Intervalo de envio (5 segundos)

// ========================================
// Setup WiFi
// ========================================
void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Conectando ao WiFi: ");
  Serial.println(ssid);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("✅ WiFi conectado!");
  Serial.print("📶 IP: ");
  Serial.println(WiFi.localIP());
}

// ========================================
// Callback MQTT (recebe mensagens)
// ========================================
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("📩 Mensagem recebida [");
  Serial.print(topic);
  Serial.print("]: ");
  
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
  }
  Serial.println();
}

// ========================================
// Reconectar ao MQTT
// ========================================
void reconnect() {
  // Loop até conectar
  while (!client.connected()) {
    Serial.print("Tentando conectar ao MQTT...");
    
    // Tenta conectar
    if (client.connect(mqtt_client_id, mqtt_user, mqtt_password)) {
      Serial.println(" ✅ Conectado!");
      
      // Publica mensagem de status
      client.publish(topic_status, "online");
      
      // Se inscreve em tópicos (opcional)
      // client.subscribe("casa/quarto/comando");
      
    } else {
      Serial.print(" ❌ Falhou, rc=");
      Serial.print(client.state());
      Serial.println(" | Tentando novamente em 5s...");
      delay(5000);
    }
  }
}

// ========================================
// Setup
// ========================================
void setup() {
  Serial.begin(115200);
  
  // Inicia DHT22
  dht.begin();
  Serial.println("🌡️  DHT22 inicializado");
  
  // Conecta ao WiFi
  setup_wifi();
  
  // Configura servidor MQTT
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

// ========================================
// Loop Principal
// ========================================
void loop() {
  // Verifica conexão MQTT
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Envia dados a cada 'interval' ms
  unsigned long now = millis();
  if (now - lastMsg > interval) {
    lastMsg = now;

    // ─────────────────────────────────
    // Lê sensor
    // ─────────────────────────────────
    float temp = dht.readTemperature();
    float umid = dht.readHumidity();

    // Verifica leitura
    if (isnan(temp) || isnan(umid)) {
      Serial.println("❌ Erro ao ler DHT22!");
      return;
    }

    // ─────────────────────────────────
    // Publica no MQTT
    // ─────────────────────────────────
    
    // Converte float para string
    char temp_str[8];
    char umid_str[8];
    dtostrf(temp, 1, 2, temp_str);  // 1 casa antes, 2 depois da vírgula
    dtostrf(umid, 1, 2, umid_str);

    // Publica temperatura
    if (client.publish(topic_temp, temp_str)) {
      Serial.print("📤 Temperatura enviada: ");
      Serial.print(temp_str);
      Serial.println(" °C");
    }

    // Publica umidade
    if (client.publish(topic_umid, umid_str)) {
      Serial.print("📤 Umidade enviada: ");
      Serial.print(umid_str);
      Serial.println(" %");
    }

    Serial.println("─────────────────────");
  }
}
```

🔧 **3. Instalação de Bibliotecas**

Arduino IDE:
1. **WiFi.h**: Já vem com ESP32
2. **PubSubClient**: Library Manager → "PubSubClient" by Nick O'Leary
3. **DHT.h**: Já instalada no exemplo anterior

📊 **4. Testando com MQTT Explorer**

Download: http://mqtt-explorer.com

Configuração:
```
Host: broker.hivemq.com
Port: 1883
Protocol: mqtt://

Subscribe to: casa/quarto/#
```

Você verá as mensagens chegando!

🔐 **5. Brokers MQTT**

**Públicos (para teste):**
├─ broker.hivemq.com:1883
├─ test.mosquitto.org:1883
└─ broker.emqx.io:1883

**Locais (mais seguro):**
├─ Mosquitto (Linux/Docker)
└─ EMQX (Docker)

**Instalar Mosquitto no Docker:**
```bash
docker run -d \
  --name mosquitto \
  -p 1883:1883 \
  eclipse-mosquitto
```

💡 **6. Melhorias**

• **JSON**: Enviar dados em formato JSON
  ```cpp
  String payload = "{\"temp\":" + String(temp) + ",\"umid\":" + String(umid) + "}";
  client.publish("casa/quarto/dados", payload.c_str());
  ```

• **QoS**: Garantir entrega
  ```cpp
  client.publish(topic, msg, true);  // retained message
  ```

• **TLS**: Conexão segura
  ```cpp
  espClient.setCACert(ca_cert);  // Certificado
  ```

🐛 **7. Troubleshooting**

❌ "WiFi não conecta":
   ✅ Verifique SSID e senha
   ✅ Teste com outro dispositivo
   ✅ Aproxime o ESP32 do roteador

❌ "MQTT não conecta":
   ✅ Teste com MQTT Explorer primeiro
   ✅ Verifique porta (1883 padrão)
   ✅ Use broker público para teste

❌ "Desconecta após alguns minutos":
   ✅ Aumente keepAlive: client.setKeepAlive(60);
   ✅ Verifique sua rede WiFi

📈 **Próximos Passos:**
├─ Criar dashboard (Node-RED, Grafana)
├─ Adicionar banco de dados (InfluxDB)
├─ Implementar alertas
└─ Criar app mobile

Precisa de ajuda com alguma dessas melhorias? 🚀
```

---

## 🔄 Transições entre Agentes

### Exemplo 6: Conversa Mista

**Usuário:**
```
Hi! I need help with two things:
1. Como usar "used to" em inglês
2. Como programar um LED no Arduino
```

**Main Agent:**
```
Olá! Vejo que você precisa de ajuda com dois tópicos diferentes. 
Vou acionar os especialistas adequados para cada um!

Vou consultar:
• Tutor de Inglês para "used to"
• Tutor de IoT para programação do LED
```

**Tutor English:**
```
📚 "USED TO" - Explicação Completa

[Explicação detalhada sobre used to...]
```

**Tutor IoT:**
```
💡 Programação de LED no Arduino

[Código e explicação detalhada...]
```

**Main Agent:**
```
✅ Pronto! Os especialistas responderam suas duas perguntas:

1️⃣ "Used to" em inglês → Veja a explicação acima
2️⃣ LED no Arduino → Código completo fornecido

Alguma dúvida adicional? 😊
```

---

## 🎯 Menções Diretas

### Exemplo 7: Forçar Agente Específico

**Usuário:**
```
@tutor-iot: What GPIO pins can I use for I2C on ESP32?
```

**Tutor IoT:**
```
📌 ESP32 I2C GPIO Pins

O ESP32 permite I2C em quase qualquer GPIO, mas há pinos padrão recomendados:

🔧 **Pinos Padrão:**
├─ SDA (Data):  GPIO 21
└─ SCL (Clock): GPIO 22

💻 **Código:**
```cpp
#include <Wire.h>

void setup() {
  Wire.begin();  // Usa GPIO 21 (SDA) e 22 (SCL) por padrão
  
  // Ou especifique outros pinos:
  // Wire.begin(SDA_PIN, SCL_PIN);
  // Exemplo: Wire.begin(16, 17);
}
```

🎯 **Pinos Alternativos:**
Você pode usar praticamente qualquer GPIO (exceto apenas input):
```cpp
Wire.begin(16, 17);   // SDA=GPIO16, SCL=GPIO17
Wire.begin(32, 33);   // SDA=GPIO32, SCL=GPIO33
```

⚠️ **Evitar:**
├─ GPIO 34-39: Apenas INPUT (sem pull-up interno)
├─ GPIO 6-11: Usados pela Flash (não mexer!)
└─ GPIO 0, 2: Usados no boot (cuidado com pull-ups)

💡 **Dica:**
Para múltiplos barramentos I2C:
```cpp
TwoWire I2Cone = TwoWire(0);
TwoWire I2Ctwo = TwoWire(1);

I2Cone.begin(21, 22);  // Barramento 1
I2Ctwo.begin(16, 17);  // Barramento 2
```

Precisa de mais alguma informação? 🔌
```

---

## 🚀 Casos de Uso Avançados

### Exemplo 8: Projeto Integrado

**Usuário:**
```
I want to create a smart home system that reads temperature and sends notifications in English when it's too hot.
```

**Main Agent:**
```
Ótimo projeto! Vou coordenar ambos os especialistas:
• Tutor IoT → Parte técnica (hardware + código)
• Tutor English → Mensagens em inglês

Primeiro, vamos com a parte técnica...
```

**Tutor IoT:**
```
🏠 Smart Home Temperature Monitor

**Componentes:**
├─ ESP32
├─ DHT22
├─ WiFi para notificações
└─ Buzzer (opcional)

**Código Base:**
```cpp
// Sistema de monitoramento com alertas
#include <WiFi.h>
#include <DHT.h>
#include <HTTPClient.h>

#define DHTPIN 4
#define DHTTYPE DHT22
#define TEMP_THRESHOLD 28.0  // Limite em °C

DHT dht(DHTPIN, DHTTYPE);

// WiFi
const char* ssid = "YOUR_WIFI";
const char* password = "YOUR_PASSWORD";

// Webhook para notificação (IFTTT, Telegram, etc)
const char* webhook_url = "https://maker.ifttt.com/trigger/temp_alert/with/key/YOUR_KEY";

void sendNotification(float temp) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    
    // Prepara payload JSON
    String payload = "{\"value1\":\"" + String(temp, 1) + "\"}";
    
    http.begin(webhook_url);
    http.addHeader("Content-Type", "application/json");
    
    int httpCode = http.POST(payload);
    
    if (httpCode > 0) {
      Serial.println("✅ Notificação enviada!");
    }
    
    http.end();
  }
}

void setup() {
  Serial.begin(115200);
  dht.begin();
  
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✅ WiFi conectado!");
}

void loop() {
  float temp = dht.readTemperature();
  
  if (!isnan(temp)) {
    Serial.printf("🌡️ Temp: %.1f°C\n", temp);
    
    if (temp > TEMP_THRESHOLD) {
      Serial.println("🚨 Temperatura alta! Enviando alerta...");
      sendNotification(temp);
      delay(300000);  // Aguarda 5 min antes do próximo alerta
    }
  }
  
  delay(10000);  // Verifica a cada 10 segundos
}
```

Agora, sobre as mensagens em inglês...
```

**Tutor English:**
```
📧 English Notification Messages

Aqui estão sugestões de mensagens para diferentes situações:

🔥 **Temperature Alerts:**

**Formal:**
• "Temperature Alert: The current temperature is {temp}°C, which exceeds the safe threshold of {threshold}°C."
• "Warning: High temperature detected in your home ({temp}°C)."

**Casual:**
• "Hey! It's getting hot in here! 🌡️ {temp}°C"
• "Temperature alert! Your room is at {temp}°C - time to turn on the AC! ❄️"

**Urgent:**
• "🚨 URGENT: Temperature reached {temp}°C!"
• "⚠️ Critical temperature: {temp}°C - Please check your home!"

📱 **Status Messages:**

**Normal:**
• "All good! Temperature is comfortable at {temp}°C 👍"
• "Everything's fine - {temp}°C ✓"

**Starting:**
• "Temperature monitor started! 🏠"
• "System online - monitoring temperature..."

**Error:**
• "Sensor error - unable to read temperature ❌"
• "Warning: Temperature sensor malfunction"

💡 **Formatting Tips:**

Para notificações por push/Telegram:
```
🌡️ Temperature Alert

Current: 32.5°C
Threshold: 28.0°C
Status: ⚠️ High

Recommendation: Turn on AC or open windows.
```

Para emails:
```
Subject: Temperature Alert - Action Required

Hi there,

The temperature in your home has reached 32.5°C, 
which is above your comfortable threshold of 28.0°C.

Recommended actions:
• Turn on the air conditioning
• Open windows for ventilation
• Check if any heat sources are active

Current status: High temperature detected
Time: 2026-02-28 14:35:00

Best regards,
Your Smart Home System
```

📚 **Vocabulary:**
├─ threshold = limite
├─ exceeds = excede
├─ detected = detectado
├─ malfunction = mau funcionamento
└─ ventilation = ventilação

Escolha o estilo que melhor se adapta ao seu projeto! 😊
```

**Main Agent:**
```
✅ Projeto completo fornecido!

Você tem:
1️⃣ Código Arduino com sistema de alertas
2️⃣ Várias opções de mensagens em inglês
3️⃣ Sugestões de formatação

Próximos passos sugeridos:
• Configure webhook no IFTTT ou Telegram
• Ajuste o threshold conforme necessário
• Escolha o estilo de mensagem
• Teste o sistema

Precisa de ajuda com alguma parte específica? 🚀
```

---

## 📝 Dicas de Uso

### ✅ Boas Práticas

1. **Seja Específico**
   - ❌ "Ajuda com código"
   - ✅ "Como conectar sensor DHT22 no ESP32?"

2. **Use Menções Diretas quando souber**
   - `@tutor-english:` para forçar inglês
   - `@tutor-iot:` para forçar IoT

3. **Forneça Contexto**
   - "Estou aprendendo inglês há 6 meses, nível intermediário"
   - "Usando ESP32 com Arduino IDE 2.0"

4. **Peça Exemplos**
   - "Pode dar exemplos práticos?"
   - "Mostre código completo com comentários"

### ⚠️ Evitar

1. **Perguntas Muito Genéricas**
   - ❌ "Me ensine inglês"
   - ✅ "Como usar present perfect?"

2. **Múltiplos Tópicos Não Relacionados**
   - ❌ "Inglês, Arduino, receita de bolo"
   - ✅ Faça perguntas separadas

3. **Falta de Informações Técnicas**
   - ❌ "Meu sensor não funciona"
   - ✅ "DHT22 retorna NaN no ESP32 GPIO4"

---

*Exemplos criados em: 2026-02-28*  
*Versão: 1.0*
