# Odoo 18 Deployment Makefile
.PHONY: help build up down restart status logs shell backup restore update clean purge reset

# Load .env file if exists
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# Default values if not defined in .env
POSTGRES_DB ?= odoo
POSTGRES_USER ?= odoo
COMPOSE_FILE ?= docker/docker-compose.yml

help:
	@echo "Odoo 18 Deployment Commands:"
	@echo "  make build       - Build the Docker images for all services"
	@echo "  make up          - Start all services"
	@echo "  make down        - Stop all services"
	@echo "  make restart     - Restart all services"
	@echo "  make status      - Show status of services"
	@echo "  make logs        - Follow logs from all services"
	@echo "  make shell       - Open a shell in the Odoo container"
	@echo "  make backup      - Backup the database"
	@echo "  make list-backups - List available backups"
	@echo "  make restore     - Restore the database (make restore BACKUP_FILE=path/to/backup)"
	@echo "  make update      - Update Odoo and rebuild the container"
	@echo "  make clean       - Remove all containers and volumes"
	@echo "  make purge       - Remove all containers, volumes, and data directories"
	@echo "  make reset       - Complete reset: purge everything and start from zero"

build:
	@echo "Building Docker images..."
	@if [ ! -f .env ]; then \
		cp .env.example .env && \
		echo "Created .env file from template. Please edit it with your configuration."; \
	fi
	@mkdir -p data/db data/odoo data/backups logs
	@docker compose -f $(COMPOSE_FILE) build

up:
	@echo "Starting all services..."
	@docker compose -f $(COMPOSE_FILE) up -d
	@echo "Services started successfully!"

down:
	@echo "Stopping all services..."
	@docker compose -f $(COMPOSE_FILE) down
	@echo "Services stopped successfully!"

restart: down up

status:
	@echo "Services status:"
	@docker compose -f $(COMPOSE_FILE) ps

logs:
	@docker compose -f $(COMPOSE_FILE) logs -f

shell:
	@echo "Opening shell in Odoo container..."
	@docker exec -it odoo-app bash

backup:
	@echo "Creating database backup..."
	@docker exec -it odoo-backup /backup.sh
	@echo "Backup completed!"

list-backups:
	@echo "Available backups:"
	@docker exec -it odoo-backup /list-backups.sh

restore:
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "Error: BACKUP_FILE parameter is required"; \
		echo "Usage: make restore BACKUP_FILE=path/to/backup"; \
		docker exec -it odoo-backup /list-backups.sh; \
		exit 1; \
	fi
	@echo "Restoring database from $(BACKUP_FILE)..."
	@docker exec -it odoo-backup /restore.sh $(BACKUP_FILE)
	@echo "Restore completed!"

update:
	@echo "Updating Odoo..."
	@docker compose -f $(COMPOSE_FILE) down
	@docker compose -f $(COMPOSE_FILE) build --no-cache odoo
	@docker compose -f $(COMPOSE_FILE) up -d
	@echo "Odoo updated successfully!"

clean:
	@echo "Removing all containers and volumes..."
	@docker compose -f $(COMPOSE_FILE) down -v
	@echo "Cleanup completed!"

purge:
	@echo "Removing all containers, volumes, and data directories..."
	@docker compose -f $(COMPOSE_FILE) down -v
	@echo "Removing Docker volumes..."
	@docker volume rm -f odoo-db-data odoo-data odoo-addons odoo-backup-data odoo-nginx-certs odoo-nginx-www 2>/dev/null || true
	@echo "Cleanup completed!"

reset:
	@echo "Performing complete system reset..."
	@echo "This will remove all data and configurations. Press Enter to continue or Ctrl+C to cancel."
	@read confirm
	@make purge
	@echo "Removing data directories..."
	@rm -rf data logs
	@echo "Removing configuration..."
	@rm -f .env
	@echo "Reset completed. Use 'make build' to start fresh."