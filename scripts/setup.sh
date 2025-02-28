#!/bin/bash

# Odoo 18 Deployment Script
# This script automates the deployment of Odoo 18 on Ubuntu 20.04
set -e

# Print with colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Source env file if exists
if [ -f "$BASE_DIR/.env" ]; then
    echo -e "${BLUE}Loading environment variables from .env file${NC}"
    source "$BASE_DIR/.env"
else
    echo -e "${RED}No .env file found. Creating from template...${NC}"
    cp "$BASE_DIR/.env.example" "$BASE_DIR/.env"
    echo -e "${GREEN}Created .env file from template. Please review and adjust settings in .env file before continuing.${NC}"
    exit 1
fi

# Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}This script must be run as root${NC}" 1>&2
   exit 1
fi

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}      Odoo 18 Deployment Automation         ${NC}"
echo -e "${GREEN}============================================${NC}"

# Create necessary directories
echo -e "${BLUE}Creating necessary directories...${NC}"
mkdir -p "$BASE_DIR/data/db" "$BASE_DIR/data/odoo" "$BASE_DIR/data/backups" "$BASE_DIR/logs"
chmod -R 777 "$BASE_DIR/data"

# Step 1: Update system and install dependencies
echo -e "${BLUE}Step 1: Installing dependencies...${NC}"
bash "$SCRIPT_DIR/install_deps.sh"

# Step 2: Setup Docker and docker-compose
echo -e "${BLUE}Step 2: Setting up Docker...${NC}"
bash "$SCRIPT_DIR/setup_docker.sh"

# Step 3: Setup Nginx
echo -e "${BLUE}Step 3: Setting up Nginx...${NC}"
bash "$SCRIPT_DIR/setup_nginx.sh"

# Step 4: Setup backup mechanism
echo -e "${BLUE}Step 4: Setting up database backup...${NC}"
bash "$SCRIPT_DIR/setup_backup.sh"

# Step 5: Start the application
echo -e "${BLUE}Step 5: Starting Odoo services...${NC}"
cd "$BASE_DIR"
make start

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}      Odoo 18 Deployment Completed!         ${NC}"
echo -e "${GREEN}============================================${NC}"
echo -e "${BLUE}Odoo should now be accessible at: http://$DOMAIN${NC}"
echo -e "${BLUE}Admin portal available at: http://$DOMAIN/web${NC}"
echo -e "${BLUE}Database: $POSTGRES_DB${NC}"
echo -e "${BLUE}Master password: $ADMIN_PASSWORD${NC}"
echo -e "${GREEN}Run 'make help' to see available commands${NC}"