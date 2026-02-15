.PHONY: build run start stop logs clean purge test help

# Variáveis
IMAGE_NAME = openclaw
CONTAINER_NAME = openclaw
PORT_HOST = 18790
PORT_CONTAINER = 18789

help:
	@echo "Comandos disponíveis:"
	@echo "  make build    - Construir a imagem Docker"
	@echo "  make run      - Executar container interativamente"
	@echo "  make start    - Iniciar container em background"
	@echo "  make stop     - Parar container"
	@echo "  make logs     - Ver logs do container"
	@echo "  make exec     - Acessar terminal do container"
	@echo "  make clean    - Remover container"
	@echo "  make purge    - Remover container e imagem"
	@echo "  make test     - Testar conexão"
	@echo "  make dashboard- Abrir dashboard no navegador"

build:
	docker build -t $(IMAGE_NAME) .

run:
	docker run -it --rm \
		-p $(PORT_HOST):$(PORT_CONTAINER) \
		--name $(CONTAINER_NAME) \
		-v $(PWD)/data:/home/openclaw/.config/openclaw \
		-v $(PWD)/logs:/logs \
		-e GEMINI_API_KEY=$$GEMINI_API_KEY \
		-e GEMINI_MODEL=gemini-2.5-flash \
		$(IMAGE_NAME) bash

start:
	docker run -d \
		-p $(PORT_HOST):$(PORT_CONTAINER) \
		--name $(CONTAINER_NAME) \
		--restart unless-stopped \
		-v $(PWD)/data:/home/openclaw/.config/openclaw \
		-v $(PWD)/logs:/logs \
		-e GEMINI_API_KEY=$$GEMINI_API_KEY \
		$(IMAGE_NAME)

stop:
	docker stop $(CONTAINER_NAME)

logs:
	docker logs -f $(CONTAINER_NAME)

exec:
	docker exec -it $(CONTAINER_NAME) bash

clean:
	docker stop $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true

purge: clean
	docker rmi $(IMAGE_NAME) || true

test:
	@echo "Testando conexão com o container..."
	@curl -s http://localhost:$(PORT_HOST)/health > /dev/null && echo "✅ Saúde OK" || echo "❌ Falha na conexão"

dashboard:
	@open http://localhost:$(PORT_HOST) || \
	xdg-open http://localhost:$(PORT_HOST) || \
	echo "Acesse: http://localhost:$(PORT_HOST)"