#!/bin/bash

# Script to setup Nginx as reverse proxy for Odoo
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Source env file for domain settings
if [ -f "$BASE_DIR/.env" ]; then
    source "$BASE_DIR/.env"
else
    echo -e "${RED}No .env file found. Please create one from the template.${NC}"
    exit 1
fi

echo -e "${BLUE}Installing Nginx...${NC}"
apt-get update
apt-get install -y nginx

# Ensure nginx is enabled to start at boot
systemctl enable nginx

# Create nginx config from template
echo -e "${BLUE}Creating Nginx configuration...${NC}"
envsubst < "$BASE_DIR/config/nginx.conf.template" > "/etc/nginx/sites-available/odoo"

# Create symlink to sites-enabled if it doesn't exist
if [ ! -L "/etc/nginx/sites-enabled/odoo" ]; then
    ln -s /etc/nginx/sites-enabled/odoo /etc/nginx/sites-available/odoo 2>/dev/null || ln -s /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/
fi

# Remove default nginx config if it exists
if [ -L "/etc/nginx/sites-enabled/default" ]; then
    rm /etc/nginx/sites-enabled/default
fi

# Configure firewall if enabled
if command -v ufw &> /dev/null; then
    echo -e "${BLUE}Configuring firewall...${NC}"
    ufw allow 'Nginx Full'
    ufw allow ssh
    
    # Enable UFW if not already enabled
    if ! ufw status | grep -q "Status: active"; then
        echo "y" | ufw enable
    fi
fi

# Test nginx configuration
echo -e "${BLUE}Testing Nginx configuration...${NC}"
nginx -t

# Restart nginx to apply changes
echo -e "${BLUE}Restarting Nginx...${NC}"
systemctl restart nginx

echo -e "${GREEN}Nginx setup completed successfully!${NC}"
echo -e "${BLUE}Odoo will be accessible at: http://$DOMAIN${NC}"