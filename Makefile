.PHONY: help up down logs ps clean init

help:
	@echo "MFC Analytics — команды:"
	@echo "  make up      — поднять сервисы (docker compose up -d)"
	@echo "  make down    — остановить сервисы"
	@echo "  make logs    — логи всех сервисов"
	@echo "  make ps      — статус контейнеров"
	@echo "  make clean   — остановить + удалить volume'ы (ОСТОРОЖНО: данные!)"

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f --tail=100

ps:
	docker compose ps

clean:
	docker compose down -v
