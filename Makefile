.PHONY: up down logs monitor backup shell clean help

# Default target
help:
	@echo "OpenClaw Docker Management"
	@echo ""
	@echo "Available targets:"
	@echo "  make up       - Start all services (docker-compose up -d)"
	@echo "  make down     - Stop all services (docker-compose down)"
	@echo "  make logs     - Show logs from all services"
	@echo "  make monitor  - Run monitoring script"
	@echo "  make backup   - Run backup script"
	@echo "  make shell    - Access OpenClaw container shell"
	@echo "  make clean    - Remove containers and volumes"
	@echo "  make help     - Show this help"

up:
	./deploy.sh

down:
	docker-compose down

logs:
	docker-compose logs -f

monitor:
	./scripts/monitor.sh

backup:
	./scripts/backup.sh

shell:
	docker-compose exec openclaw bash

clean:
	docker-compose down -v --remove-orphans
	docker system prune -f

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
