.PHONY: help install install-docker install-kubectl install-minikube install-helm install-skaffold install-go install-node install-playwright install-godog dev test test-e2e clean

# Detect OS
UNAME_S := $(shell uname -s)
ifeq ($(OS),Windows_NT)
    DETECTED_OS := Windows
else ifeq ($(UNAME_S),Darwin)
    DETECTED_OS := MacOS
else
    DETECTED_OS := Linux
endif

help: ## Show this help message
	@echo "Card Separator - Developer Setup"
	@echo ""
	@echo "Detected OS: $(DETECTED_OS)"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install all required developer tools
	@echo "🚀 Installing all developer tools..."
	@$(MAKE) install-docker
	@$(MAKE) install-kubectl
	@$(MAKE) install-minikube
	@$(MAKE) install-helm
	@$(MAKE) install-skaffold
	@$(MAKE) install-go
	@$(MAKE) install-node
	@$(MAKE) install-playwright
	@$(MAKE) install-godog
	@echo "✅ All tools installed!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Start Minikube: make k8s-start"
	@echo "  2. Deploy to k8s: make dev"
	@echo "  3. Run tests: make test"

install-docker: ## Install Docker
	@echo "📦 Installing Docker..."
ifeq ($(DETECTED_OS),Windows)
	@echo "Please install Docker Desktop for Windows from: https://www.docker.com/products/docker-desktop"
	@echo "After installation, restart your terminal and run: make install"
else ifeq ($(DETECTED_OS),MacOS)
	@which docker > /dev/null || (echo "Installing Docker Desktop..." && brew install --cask docker)
else
	@which docker > /dev/null || (curl -fsSL https://get.docker.com | sh && sudo usermod -aG docker $$USER)
endif
	@docker --version || echo "⚠️  Docker installation requires manual setup"

install-kubectl: ## Install kubectl
	@echo "☸️  Installing kubectl..."
ifeq ($(DETECTED_OS),Windows)
	@where kubectl > nul 2>&1 || (echo "Installing kubectl..." && choco install kubernetes-cli -y)
else ifeq ($(DETECTED_OS),MacOS)
	@which kubectl > /dev/null || brew install kubectl
else
	@which kubectl > /dev/null || (curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x kubectl && sudo mv kubectl /usr/local/bin/)
endif
	@kubectl version --client || echo "⚠️  kubectl not found"

install-minikube: ## Install Minikube
	@echo "🎡 Installing Minikube..."
ifeq ($(DETECTED_OS),Windows)
	@where minikube > nul 2>&1 || (echo "Installing Minikube..." && choco install minikube -y)
else ifeq ($(DETECTED_OS),MacOS)
	@which minikube > /dev/null || brew install minikube
else
	@which minikube > /dev/null || (curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube)
endif
	@minikube version || echo "⚠️  Minikube not found"

install-helm: ## Install Helm
	@echo "⎈ Installing Helm..."
ifeq ($(DETECTED_OS),Windows)
	@where helm > nul 2>&1 || (echo "Installing Helm..." && choco install kubernetes-helm -y)
else ifeq ($(DETECTED_OS),MacOS)
	@which helm > /dev/null || brew install helm
else
	@which helm > /dev/null || (curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash)
endif
	@helm version || echo "⚠️  Helm not found"

install-skaffold: ## Install Skaffold
	@echo "🏗️  Installing Skaffold..."
ifeq ($(DETECTED_OS),Windows)
	@where skaffold > nul 2>&1 || (echo "Installing Skaffold..." && choco install skaffold -y)
else ifeq ($(DETECTED_OS),MacOS)
	@which skaffold > /dev/null || brew install skaffold
else
	@which skaffold > /dev/null || (curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && sudo install skaffold /usr/local/bin/)
endif
	@skaffold version || echo "⚠️  Skaffold not found"

install-go: ## Install Go
	@echo "🐹 Checking Go installation..."
	@go version 2>/dev/null || echo "⚠️  Please install Go from https://golang.org/dl/"

install-node: ## Install Node.js and npm
	@echo "📗 Checking Node.js installation..."
	@node --version 2>/dev/null || echo "⚠️  Please install Node.js from https://nodejs.org/"
	@npm --version 2>/dev/null || echo "⚠️  npm not found"

install-playwright: ## Install Playwright for E2E testing
	@echo "🎭 Installing Playwright..."
	@mkdir -p e2e
	@cd e2e && (test -f package.json || npm init -y)
	@cd e2e && npm install -D @playwright/test
	@cd e2e && npx playwright install
	@echo "✅ Playwright installed"

install-godog: ## Install Godog for BDD testing
	@echo "🥒 Installing Godog..."
	@go install github.com/cucumber/godog/cmd/godog@latest
	@echo "✅ Godog installed"

# Kubernetes cluster management
k8s-start: ## Start Minikube cluster
	@echo "🚀 Starting Minikube cluster..."
	@minikube start --cpus=4 --memory=8g --driver=docker
	@minikube addons enable ingress
	@echo "✅ Minikube cluster ready"

k8s-stop: ## Stop Minikube cluster
	@echo "🛑 Stopping Minikube cluster..."
	@minikube stop

k8s-delete: ## Delete Minikube cluster
	@echo "🗑️  Deleting Minikube cluster..."
	@minikube delete

k8s-status: ## Check Minikube status
	@minikube status

# Development workflows
dev: ## Start development with Skaffold (local K8s)
	@echo "🏗️  Starting development environment..."
	@skaffold dev --port-forward

dev-docker: ## Start development with Docker Compose
	@echo "🐋 Starting Docker Compose..."
	@docker-compose up --build

deploy-staging: ## Deploy to staging environment
	@echo "🚀 Deploying to staging..."
	@skaffold run -p staging

deploy-prod: ## Deploy to production environment
	@echo "🚀 Deploying to production..."
	@skaffold run -p prod

# Backend
backend: ## Run backend locally
	@echo "🔧 Starting backend..."
	@cd backend && go run main.go

backend-build: ## Build backend binary
	@echo "🔨 Building backend..."
	@cd backend && go build -o bin/server main.go

backend-test: ## Run backend unit tests
	@echo "🧪 Running backend tests..."
	@cd backend && go test ./...

# Frontend
frontend: ## Run frontend locally
	@echo "🎨 Starting frontend..."
	@cd web && npm run dev

frontend-install: ## Install frontend dependencies
	@echo "📦 Installing frontend dependencies..."
	@cd web && npm install

frontend-build: ## Build frontend for production
	@echo "🔨 Building frontend..."
	@cd web && npm run build

# Testing
test: ## Run all tests
	@echo "🧪 Running all tests..."
	@$(MAKE) backend-test
	@$(MAKE) test-integration
	@$(MAKE) test-e2e

test-integration: ## Run Terratest integration tests
	@echo "🔬 Running integration tests with Terratest..."
	@cd test && go test -v -timeout 30m

test-e2e: ## Run Playwright E2E tests
	@echo "🎭 Running E2E tests with Playwright..."
	@cd e2e && npx playwright test

test-godog: ## Run Godog BDD tests
	@echo "🥒 Running BDD tests with Godog..."
	@cd test && godog run

# Database
db-migrate: ## Run database migrations
	@echo "📊 Running database migrations..."
	@cd backend && go run migrations/migrate.go

# Utilities
logs: ## Show logs from all services
	@docker-compose logs -f

logs-backend: ## Show backend logs
	@docker-compose logs -f backend

logs-frontend: ## Show frontend logs
	@docker-compose logs -f frontend

logs-k8s: ## Show Kubernetes logs
	@kubectl logs -f -l app=backend --all-containers=true

clean: ## Clean up generated files and caches
	@echo "🧹 Cleaning up..."
	@rm -rf backend/bin backend/cache backend/data/*.db
	@rm -rf web/build web/.svelte-kit web/node_modules/.cache
	@rm -rf e2e/test-results e2e/playwright-report
	@docker-compose down -v
	@echo "✅ Cleanup complete"

fmt: ## Format code
	@echo "💅 Formatting code..."
	@cd backend && go fmt ./...
	@cd web && npm run format || true

lint: ## Lint code
	@echo "🔍 Linting code..."
	@cd backend && golint ./... || echo "Install golint: go install golang.org/x/lint/golint@latest"
	@cd web && npm run lint || true

# Docker
docker-build: ## Build Docker images
	@echo "🐋 Building Docker images..."
	@docker-compose build

docker-up: ## Start Docker services
	@echo "🐋 Starting Docker services..."
	@docker-compose up -d

docker-down: ## Stop Docker services
	@echo "🐋 Stopping Docker services..."
	@docker-compose down

docker-clean: ## Clean Docker resources
	@echo "🐋 Cleaning Docker resources..."
	@docker-compose down -v --remove-orphans
	@docker system prune -f

# Helm
helm-lint: ## Lint Helm charts
	@echo "⎈ Linting Helm charts..."
	@helm lint helm/

helm-template: ## Show Helm template output
	@echo "⎈ Rendering Helm templates..."
	@helm template card-separator helm/

helm-install: ## Install Helm chart
	@echo "⎈ Installing Helm chart..."
	@helm install card-separator helm/

helm-upgrade: ## Upgrade Helm chart
	@echo "⎈ Upgrading Helm chart..."
	@helm upgrade card-separator helm/

helm-uninstall: ## Uninstall Helm chart
	@echo "⎈ Uninstalling Helm chart..."
	@helm uninstall card-separator

# Health checks
health: ## Check backend health
	@curl http://localhost:8080/api/health | jq || curl http://localhost:8080/api/health

cache-stats: ## Show cache statistics
	@curl http://localhost:8080/api/cache/stats | jq || curl http://localhost:8080/api/cache/stats

.DEFAULT_GOAL := help
