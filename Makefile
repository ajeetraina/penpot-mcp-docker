# PenPot MCP Docker - Makefile
.PHONY: help setup build up down logs clean test dev prod status health

# Default target
.DEFAULT_GOAL := help

# Variables
COMPOSE_FILE := docker-compose.yml
DEV_COMPOSE_FILE := docker-compose.dev.yml
IMAGE_NAME := penpot-mcp
CONTAINER_NAME := penpot-mcp-server

# Docker compose command detection
DOCKER_COMPOSE := $(shell which docker-compose 2>/dev/null || echo "docker compose")

help: ## Show this help message
	@echo "PenPot MCP Server - Docker Commands"
	@echo "===================================="
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "Examples:"
	@echo "  make setup     # Complete setup with source code"
	@echo "  make dev       # Start development environment"
	@echo "  make prod      # Start production environment"
	@echo "  make logs      # View container logs"

setup: ## Complete setup (clone source, build, and start)
	@echo "🚀 Setting up PenPot MCP Docker..."
	@chmod +x setup.sh
	@./setup.sh setup

clone-source: ## Clone the original source code
	@echo "📥 Cloning source repository..."
	@git clone https://github.com/montevive/penpot-mcp.git penpot-mcp-source || true
	@rsync -av --exclude='.git' --exclude='__pycache__' penpot-mcp-source/ ./
	@rm -rf penpot-mcp-source
	@echo "✅ Source code ready!"

build: clone-source ## Build Docker image
	@echo "🔨 Building Docker image..."
	@docker build -t $(IMAGE_NAME):latest .
	@echo "✅ Image built successfully!"

up: ## Start services in background
	@echo "🚀 Starting PenPot MCP services..."
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up -d
	@echo "✅ Services started!"
	@make status

down: ## Stop and remove containers
	@echo "🛑 Stopping PenPot MCP services..."
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down
	@echo "✅ Services stopped!"

dev: clone-source ## Start development environment
	@echo "🛠️ Starting development environment..."
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) -f $(DEV_COMPOSE_FILE) up -d
	@echo "✅ Development environment started!"
	@make status

prod: clone-source ## Start production environment
	@echo "🏭 Starting production environment..."
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up -d --remove-orphans
	@echo "✅ Production environment started!"
	@make status

restart: ## Restart services
	@echo "🔄 Restarting PenPot MCP services..."
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) restart
	@echo "✅ Services restarted!"

logs: ## Show container logs
	@echo "📋 Showing logs for PenPot MCP..."
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) logs -f penpot-mcp

logs-all: ## Show all container logs
	@echo "📋 Showing all logs..."
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) logs -f

status: ## Show service status
	@echo "📊 Service Status:"
	@echo "=================="
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) ps
	@echo
	@echo "🔍 Container Details:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter name=penpot

health: ## Check service health
	@echo "🏥 Checking service health..."
	@curl -f http://localhost:5000/health 2>/dev/null && echo "✅ Service is healthy!" || echo "❌ Service is not responding"

test: ## Run tests
	@echo "🧪 Running tests..."
	@docker build --target test -t $(IMAGE_NAME):test . || echo "❌ Tests failed"

shell: ## Access container shell
	@echo "🐚 Accessing container shell..."
	@docker exec -it $(CONTAINER_NAME) /bin/bash

clean: ## Clean up containers and images
	@echo "🧹 Cleaning up..."
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down -v --remove-orphans
	@docker image prune -f --filter "reference=$(IMAGE_NAME)"
	@docker volume prune -f
	@echo "✅ Cleanup completed!"

clean-all: ## Clean up everything (containers, images, volumes)
	@echo "🧹 Deep cleaning..."
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down -v --remove-orphans --rmi all
	@docker system prune -f
	@echo "✅ Deep cleanup completed!"

env: ## Create .env file from template
	@echo "⚙️ Setting up environment file..."
	@cp .env.example .env
	@echo "✅ .env file created! Please edit it with your credentials."

backup: ## Backup persistent data
	@echo "💾 Creating backup..."
	@mkdir -p backups
	@docker run --rm -v penpot-mcp-docker_penpot_cache:/data -v $(PWD)/backups:/backup alpine tar czf /backup/penpot_cache_$(shell date +%Y%m%d_%H%M%S).tar.gz -C /data .
	@echo "✅ Backup created in ./backups/"

restore: ## Restore from backup (specify BACKUP_FILE=filename)
	@echo "🔄 Restoring from backup..."
	@test -n "$(BACKUP_FILE)" || (echo "❌ Please specify BACKUP_FILE=filename" && exit 1)
	@docker run --rm -v penpot-mcp-docker_penpot_cache:/data -v $(PWD)/backups:/backup alpine tar xzf /backup/$(BACKUP_FILE) -C /data
	@echo "✅ Backup restored!"

monitor: ## Monitor resource usage
	@echo "📊 Resource monitoring (Press Ctrl+C to stop)..."
	@docker stats $(CONTAINER_NAME)

update: ## Pull latest changes and rebuild
	@echo "🔄 Updating PenPot MCP Docker..."
	@git pull origin main
	@make clean
	@make setup
	@echo "✅ Update completed!"

# Production specific targets
prod-deploy: ## Deploy to production (with health checks)
	@echo "🚀 Deploying to production..."
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up -d
	@echo "⏳ Waiting for services to be ready..."
	@sleep 30
	@make health
	@echo "✅ Production deployment completed!"

prod-scale: ## Scale production services (usage: make prod-scale REPLICAS=3)
	@echo "⚖️ Scaling services..."
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up -d --scale penpot-mcp=$(REPLICAS)
	@echo "✅ Scaling completed!"

# Development specific targets
dev-logs: ## Show development logs
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) -f $(DEV_COMPOSE_FILE) logs -f

dev-down: ## Stop development environment
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) -f $(DEV_COMPOSE_FILE) down

dev-shell: ## Access development container shell
	@docker exec -it $(CONTAINER_NAME) /bin/bash

# CI/CD targets
ci-test: ## Run CI tests
	@echo "🧪 Running CI tests..."
	@docker build --target test -t $(IMAGE_NAME):ci-test .
	@docker run --rm $(IMAGE_NAME):ci-test

ci-build: ## Build for CI
	@echo "🔨 Building for CI..."
	@docker build -t $(IMAGE_NAME):ci .

# Help target with better formatting
info: ## Show system information
	@echo "System Information:"
	@echo "==================="
	@echo "Docker version: $$(docker --version)"
	@echo "Docker Compose: $$($(DOCKER_COMPOSE) --version)"
	@echo "Current directory: $$(pwd)"
	@echo "Available images: $$(docker images $(IMAGE_NAME) --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}')"
	@echo "Running containers: $$(docker ps --filter name=penpot --format 'table {{.Names}}\t{{.Status}}')"
