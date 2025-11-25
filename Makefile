# Makefile for UIT Go Backend

.PHONY: up down restart logs seed test clean help

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Start all services in background
	docker compose up -d

down: ## Stop and remove all services
	docker compose down

restart: down up ## Restart all services

logs: ## Follow logs of all services
	docker compose logs -f

seed: ## Seed initial data (User & Drivers)
	chmod +x ./scripts/seed-data.sh
	./scripts/seed-data.sh

test-load: ## Run k6 load test (Spike Test)
	docker run --rm -i \
		-v $(PWD)/tests/k6:/scripts \
		--network host \
		grafana/k6 run /scripts/spike-test.js

clean: ## Remove all containers and volumes
	docker compose down -v

status: ## Check status of containers
	docker compose ps
