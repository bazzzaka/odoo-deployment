#!/bin/bash

# Manual Database Initialization Script for Odoo
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment variables with absolute path
ENV_FILE="${BASE_DIR}/.env"
if [ -f "$ENV_FILE" ]; then
    echo -e "${BLUE}Loading environment variables from ${ENV_FILE}${NC}"
    set -a  # automatically export all variables
    source "$ENV_FILE"
    set +a  # stop automatically exporting
else
    echo -e "${RED}Error: .env file not found at ${ENV_FILE}${NC}"
    exit 1
fi

# Verify environment variables are loaded
if [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ] || [ -z "$POSTGRES_DB" ]; then
    echo -e "${RED}Error: Required environment variables are not set!${NC}"
    echo -e "Please check your .env file. Required variables: POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB"
    exit 1
fi

# Set default values for optional variables
INIT_MODULES="${INIT_MODULES:-base,web,mail}"
WITHOUT_DEMO="${WITHOUT_DEMO:-all}"

echo -e "${BLUE}Starting manual database initialization...${NC}"
echo -e "${BLUE}Using database: ${POSTGRES_DB}${NC}"
echo -e "${BLUE}Using user: ${POSTGRES_USER}${NC}"
echo -e "${BLUE}Using modules: ${INIT_MODULES}${NC}"

# Check if containers are running
if ! docker ps | grep -q odoo-db; then
    echo -e "${RED}Error: Database container (odoo-db) is not running.${NC}"
    echo -e "Please start the containers with 'make start' first."
    exit 1
fi

# Ask for confirmation
echo -e "${RED}WARNING: This will DROP the existing database '${POSTGRES_DB}' if it exists!${NC}"
read -p "Do you want to continue? (y/n): " -n 1 -r
echo    # Move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Operation cancelled.${NC}"
    exit 0
fi

# Create log directory with proper permissions
echo -e "${BLUE}Creating log directory with proper permissions...${NC}"
mkdir -p "${BASE_DIR}/logs/odoo"
chmod -R 777 "${BASE_DIR}/logs"

echo -e "${BLUE}Completely stopping all Odoo services...${NC}"
docker stop odoo-app || true
docker rm odoo-app || true

echo -e "${BLUE}Dropping existing database if it exists...${NC}"
docker exec odoo-db psql -U "$POSTGRES_USER" -c "DROP DATABASE IF EXISTS $POSTGRES_DB;" postgres

echo -e "${BLUE}Creating database...${NC}"
docker exec odoo-db psql -U "$POSTGRES_USER" -c "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER TEMPLATE template0 ENCODING 'UTF8';" postgres

echo -e "${BLUE}Starting a temporary Odoo container for initialization...${NC}"
docker run --rm -d \
    --name odoo-init \
    --network odoo_odoo-network \
    -e DB_HOST=db \
    -e DB_PORT=5432 \
    -e POSTGRES_USER=$POSTGRES_USER \
    -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
    -e POSTGRES_DB=$POSTGRES_DB \
    -e ADMIN_PASSWORD=$ADMIN_PASSWORD \
    -v "${BASE_DIR}/data/odoo":/var/lib/odoo \
    -v "${BASE_DIR}/addons":/mnt/extra-addons \
    -v "${BASE_DIR}/logs/odoo":/var/log/odoo \
    odoo-odoo \
    odoo --stop-after-init --no-http --init=${INIT_MODULES} --database=${POSTGRES_DB} --without-demo=${WITHOUT_DEMO}

echo -e "${BLUE}Waiting for initialization to complete...${NC}"
docker wait odoo-init || true

echo -e "${GREEN}Database initialization completed.${NC}"
echo -e "${BLUE}Starting regular Odoo container...${NC}"
cd "$BASE_DIR" && docker compose -f docker/docker-compose.yml up -d odoo

echo -e "${GREEN}Odoo is now ready to use with a freshly initialized database.${NC}"
echo -e "${BLUE}You can access it at http://localhost:8069${NC}"