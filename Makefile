# Odoo 18 Deployment Makefile
.PHONY: help setup dev prod start stop restart status logs shell backup restore update clean install-modules

# Load environment variables from .env file if it exists
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

COMPOSE_FILE = docker/docker-compose.yml
ENV_FILE = .env

# Set default compose project name
COMPOSE_PROJECT_NAME ?= odoo

help:
	@echo "Odoo 18 Deployment - Available Commands:"
	@echo "  make setup         - Prepare the environment for first-time setup"
	@echo "  make dev           - Start development environment"
	@echo "  make prod          - Start production environment"
	@echo "  make start         - Start all services"
	@echo "  make stop          - Stop all services"
	@echo "  make restart       - Restart all services"
	@echo "  make status        - Show status of services"
	@echo "  make logs          - Follow logs from all services"
	@echo "  make shell         - Open a shell in the Odoo container"
	@echo "  make backup        - Backup the database"
	@echo "  make restore       - Restore the database (make restore BACKUP_FILE=path/to/backup)"
	@echo "  make update        - Update Odoo and rebuild the container"
	@echo "  make clean         - Remove all containers and volumes"
	@echo "  make install-modules MODULES=module1,module2 - Install or update Odoo modules"

setup:
	@echo "Setting up Odoo environment..."
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "Creating .env file from template..."; \
		cp .env.example $(ENV_FILE); \
		echo "Please edit $(ENV_FILE) with your configuration."; \
		echo "Then run 'make setup' again to continue."; \
		exit 1; \
	fi
	@mkdir -p data/db data/odoo data/backups logs addons
	@echo "Creating Docker network..."
	@docker network create odoo-network 2>>logs/docker-errors.log || true
	@echo "Environment setup completed. You can now start the system with 'make prod' or 'make dev'"

dev:
	@echo "Starting development environment..."
	@export BUILD_ENV=dev && docker compose -f $(COMPOSE_FILE) up -d --build
	@echo "Development environment started. Access Odoo at http://localhost:8069"

prod:
	@echo "Starting production environment..."
	@export BUILD_ENV=prod && docker compose -f $(COMPOSE_FILE) up -d --build
	@echo "Production environment started. Access Odoo at http://$(DOMAIN)"

start:
	@echo "Starting Odoo services..."
	@docker compose -f $(COMPOSE_FILE) up -d
	@echo "Services started successfully"

stop:
	@echo "Stopping Odoo services..."
	@docker compose -f $(COMPOSE_FILE) down
	@echo "Services stopped successfully"

restart: stop start

status:
	@echo "Current status of services:"
	@docker compose -f $(COMPOSE_FILE) ps

logs:
	@docker compose -f $(COMPOSE_FILE) logs -f

shell:
	@echo "Opening shell in Odoo container..."
	@docker exec -it odoo-app bash

backup:
	@echo "Creating database backup..."
	@mkdir -p data/backups
	@docker exec odoo-db pg_dump -U $(POSTGRES_USER) $(POSTGRES_DB) -F c > data/backups/$(POSTGRES_DB)_$(shell date +%Y%m%d_%H%M%S).dump
	@echo "Backup completed: data/backups/$(POSTGRES_DB)_$(shell date +%Y%m%d_%H%M%S).dump"

restore:
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "Error: BACKUP_FILE parameter is required"; \
		echo "Usage: make restore BACKUP_FILE=path/to/backup.dump"; \
		exit 1; \
	fi
	@echo "Restoring database from $(BACKUP_FILE)..."
	@docker compose -f $(COMPOSE_FILE) stop odoo
	@docker exec -i odoo-db pg_restore -U $(POSTGRES_USER) -d $(POSTGRES_DB) -c < $(BACKUP_FILE)
	@docker compose -f $(COMPOSE_FILE) start odoo
	@echo "Database restore completed"

update:
	@echo "Updating Odoo..."
	@docker compose -f $(COMPOSE_FILE) build --no-cache odoo
	@docker compose -f $(COMPOSE_FILE) up -d
	@echo "Odoo updated successfully"

clean:
	@echo "Cleaning up containers and volumes..."
	@docker compose -f $(COMPOSE_FILE) down -v
	@echo "Cleanup completed"

install-modules:
	@if [ -z "$(MODULES)" ]; then \
		echo "Error: MODULES parameter is required"; \
		echo "Usage: make install-modules MODULES=module1,module2"; \
		exit 1; \
	fi
	@echo "Installing/updating modules: $(MODULES)"
	@chmod +x scripts/install_modules.sh
	@scripts/install_modules.sh $(MODULES)
	@echo "Module installation completed"