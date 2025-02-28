# Odoo 18 Deployment Makefile
.PHONY: help setup start stop restart status logs shell backup restore update clean

# Load .env file if exists
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# Default values if not defined in .env
POSTGRES_DB ?= odoo
POSTGRES_USER ?= odoo

help:
	@echo "Odoo 18 Deployment Commands:"
	@echo "  make setup       - Prepare the environment and setup all components"
	@echo "  make start       - Start all services"
	@echo "  make stop        - Stop all services"
	@echo "  make restart     - Restart all services"
	@echo "  make status      - Show status of services"
	@echo "  make logs        - Follow logs from all services"
	@echo "  make shell       - Open a shell in the Odoo container"
	@echo "  make backup      - Backup the database"
	@echo "  make restore     - Restore the database (make restore BACKUP_FILE=path/to/backup)"
	@echo "  make update      - Update Odoo and rebuild the container"
	@echo "  make clean       - Remove all containers and volumes"

setup:
	@echo "Setting up the environment..."
	@if [ ! -f .env ]; then \
		cp .env.example .env && \
		echo "Created .env file from template. Please edit it with your configuration."; \
		exit 1; \
	fi
	@bash scripts/setup.sh

start:
	@echo "Starting all services..."
	@docker compose -f docker/docker-compose.yml up -d
	@echo "Services started successfully!"

stop:
	@echo "Stopping all services..."
	@docker compose -f docker/docker-compose.yml down
	@echo "Services stopped successfully!"

restart: stop start

status:
	@echo "Services status:"
	@docker compose -f docker/docker-compose.yml ps

logs:
	@docker compose -f docker/docker-compose.yml logs -f

shell:
	@echo "Opening shell in Odoo container..."
	@docker exec -it odoo-app bash

backup:
	@echo "Creating database backup..."
	@bash scripts/backup_database.sh
	@echo "Backup completed!"

restore:
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "Error: BACKUP_FILE parameter is required"; \
		echo "Usage: make restore BACKUP_FILE=path/to/backup"; \
		exit 1; \
	fi
	@echo "Restoring database from $(BACKUP_FILE)..."
	@bash scripts/restore_database.sh $(BACKUP_FILE)
	@echo "Restore completed!"

update:
	@echo "Updating Odoo..."
	@docker compose -f docker/docker-compose.yml down
	@docker compose -f docker/docker-compose.yml build --no-cache odoo
	@docker compose -f docker/docker-compose.yml up -d
	@echo "Odoo updated successfully!"

clean:
	@echo "Removing all containers and volumes..."
	@docker compose -f docker/docker-compose.yml down -v
	@echo "Cleanup completed!"