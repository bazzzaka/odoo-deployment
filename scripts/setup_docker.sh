#!/bin/bash

# Script to prepare Docker environment for Odoo deployment
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Check for Docker installation
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker manually.${NC}"
    exit 1
fi

# Verify Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Docker daemon is not running. Please start Docker service.${NC}"
    exit 1
fi

# Create Docker network
echo -e "${BLUE}Creating Docker network for Odoo...${NC}"
if ! docker network inspect odoo-network &> /dev/null; then
    docker network create odoo-network
    echo -e "${GREEN}Docker network 'odoo-network' created successfully.${NC}"
else
    echo -e "${BLUE}Docker network 'odoo-network' already exists.${NC}"
fi

# Create directories for persistent data
echo -e "${BLUE}Creating data directories...${NC}"
mkdir -p "$BASE_DIR/data/db"
mkdir -p "$BASE_DIR/data/odoo"
mkdir -p "$BASE_DIR/data/backups"
mkdir -p "$BASE_DIR/logs"

# Set proper permissions for data directories
echo -e "${BLUE}Setting permissions for data directories...${NC}"
chmod -R 777 "$BASE_DIR/data"

# Verify required images are available
REQUIRED_IMAGES=("postgres:15-alpine" "nginx:alpine")

for image in "${REQUIRED_IMAGES[@]}"; do
    if [[ "$(docker images -q "$image" 2> /dev/null)" == "" ]]; then
        echo -e "${BLUE}Pulling Docker image: $image${NC}"
        docker pull "$image"
    else
        echo -e "${BLUE}Image $image already exists locally.${NC}"
    fi
done

# Final status
echo -e "${GREEN}Docker environment preparation completed successfully.${NC}"