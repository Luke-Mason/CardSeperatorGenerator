.PHONY: help dev up down build clean logs test backend frontend install

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install all dependencies (frontend + backend)
	@echo "Installing frontend dependencies..."
	cd web && npm install
	@echo "Installing backend dependencies..."
	cd backend && go mod download
	@echo "Done!"

dev: ## Start development environment with Docker Compose
	docker-compose up --build

up: ## Start services (without rebuilding)
	docker-compose up

down: ## Stop all services
	docker-compose down

build: ## Build all Docker images
	docker-compose build

clean: ## Clean up containers, volumes, and cache
	docker-compose down -v
	rm -rf backend/cache
	@echo "Cleaned up!"

logs: ## Show logs from all services
	docker-compose logs -f

logs-backend: ## Show backend logs only
	docker-compose logs -f backend

logs-frontend: ## Show frontend logs only
	docker-compose logs -f frontend

backend: ## Run backend locally (without Docker)
	cd backend && go run src/main.go

frontend: ## Run frontend locally (without Docker)
	cd web && npm run dev

test: ## Run tests
	cd backend && go test ./...
	cd web && npm run test

fmt: ## Format code
	cd backend && go fmt ./...
	cd web && npm run format

lint: ## Lint code
	cd web && npm run lint
	hadolint backend/Dockerfile
	hadolint web/Dockerfile.dev 2>/dev/null || echo "hadolint not installed, skipping Docker linting"

cache-stats: ## Show image cache statistics
	curl http://localhost:8080/api/cache/stats | jq

health: ## Check backend health
	curl http://localhost:8080/api/health | jq

.DEFAULT_GOAL := help
