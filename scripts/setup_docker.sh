#!/bin/bash

# Script to install Docker and Docker Compose
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}Installing Docker...${NC}"

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose v2
echo -e "${BLUE}Installing Docker Compose...${NC}"
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

# Test Docker installation
echo -e "${BLUE}Testing Docker installation...${NC}"
docker --version
docker compose version

# Create Docker network
echo -e "${BLUE}Creating Docker network...${NC}"
docker network create odoo-network || true

# Create directories for the volumes if not exist
echo -e "${BLUE}Creating directories for Docker volumes...${NC}"
mkdir -p "$BASE_DIR/data/db"
mkdir -p "$BASE_DIR/data/odoo"
mkdir -p "$BASE_DIR/data/backups"
mkdir -p "$BASE_DIR/logs"

# Set proper permissions for the data directories
echo -e "${BLUE}Setting proper permissions for data directories...${NC}"
chmod -R 777 "$BASE_DIR/data"

# Pull necessary Docker images
echo -e "${BLUE}Pulling necessary Docker images...${NC}"
docker pull postgres:15-alpine
docker pull nginx:alpine

echo -e "${GREEN}Docker and Docker Compose installed successfully!${NC}"