# Executables (local)
DOCKER_COMP_APP = docker compose -f docker-compose.app.yaml
DOCKER_COMP_DB = docker compose -f docker-compose.db.yaml

# Docker containers
PHP_CONT = $(DOCKER_COMP_APP) exec php

# Executables
PHP      = $(PHP_CONT) php
COMPOSER = $(PHP_CONT) composer
SYMFONY  = $(PHP) bin/console

# Misc
.DEFAULT_GOAL = help
.PHONY        : help build-all up-all start-all down-all stop-all logs-app logs-db sh bash migrate

## —— 🎵 🐳 Symfony Docker Makefile (2 Docker Compose) 🐳 🎵 ———————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— Docker 🐳 (Database) —————————————————————————————————————————————————————
build-db: ## Build the PostgreSQL image
	@$(DOCKER_COMP_DB) build --no-cache

up-db: ## Start the database in detached mode
	@$(DOCKER_COMP_DB) up -d

down-db: ## Stop the database
	@$(DOCKER_COMP_DB) down --remove-orphans

logs-db: ## Show database logs
	@$(DOCKER_COMP_DB) logs --tail=0 --follow

## —— Docker 🐳 (Application) ——————————————————————————————————————————————————
build-app: ## Build the application images (Symfony, Adminer, Composer)
	@$(DOCKER_COMP_APP) build --no-cache

up-app: ## Start the application in detached mode
	@$(DOCKER_COMP_APP) up -d

down-app: ## Stop the application
	@$(DOCKER_COMP_APP) down --remove-orphans

logs-app: ## Show application logs
	@$(DOCKER_COMP_APP) logs --tail=0 --follow

## —— Docker 🐳 (All) ——————————————————————————————————————————————————————————
build-all: build-db build-app ## Build all Docker images

start-all: ## Build and start all containers (DB + App)
	@echo "🔨 Building database..."
	@$(DOCKER_COMP_DB) build --no-cache
	@echo "🚀 Starting database..."
	@$(DOCKER_COMP_DB) up -d
	@echo "⏳ Waiting for database to be ready..."
	@sleep 5
	@echo "🔨 Building application..."
	@$(DOCKER_COMP_APP) build --no-cache
	@echo "🚀 Starting application..."
	@$(DOCKER_COMP_APP) up -d
	@echo "📊 Running migrations..."
	@sleep 3
	@$(SYMFONY) doctrine:migrations:migrate --no-interaction
	@echo "✅ Project started successfully!"
	@echo "🌐 Application: https://localhost"
	@echo "🗄️  Adminer: http://localhost:8081"
	@echo "📡 API: https://localhost/api/todos"

stop-all: down-app down-db ## Stop all containers

logs-all: ## Show all logs
	@$(DOCKER_COMP_DB) logs --tail=50 &
	@$(DOCKER_COMP_APP) logs --tail=50

## —— Application Commands 🎯 ——————————————————————————————————————————————————
sh: ## Connect to the PHP container (sh)
	@$(PHP_CONT) sh

bash: ## Connect to the PHP container (bash)
	@$(PHP_CONT) bash

migrate: ## Run database migrations
	@$(SYMFONY) doctrine:migrations:migrate --no-interaction

## —— Composer 🧙 ——————————————————————————————————————————————————————————————
composer: ## Run composer, pass the parameter "c=" to run a given command, example: make composer c='req symfony/orm-pack'
	@$(eval c ?=)
	@$(COMPOSER) $(c)
