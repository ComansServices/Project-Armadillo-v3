SHELL := /bin/bash

.PHONY: help up down logs ps test bootstrap clean

help:
	@echo "Armadillo v3 dev helpers"
	@echo "  make up        -> start full stack (build + detached)"
	@echo "  make down      -> stop stack"
	@echo "  make logs      -> tail logs"
	@echo "  make ps        -> list containers"
	@echo "  make test      -> run health + queue smoke test"
	@echo "  make bootstrap -> install Docker tools + configure plugin path"
	@echo "  make clean     -> down + remove volumes + prune dangling images"

up:
	docker compose up --build -d

down:
	docker compose down

logs:
	docker compose logs -f --tail=150

ps:
	docker compose ps

test:
	bash scripts/smoke-test.sh

bootstrap:
	brew install docker docker-compose docker-buildx colima
	mkdir -p $$HOME/.docker
	python3 scripts/configure_docker_plugins.py

clean:
	docker compose down -v --remove-orphans
	docker image prune -f
