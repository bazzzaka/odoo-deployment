#!/bin/bash

# Script to install additional Odoo modules after initial setup

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    source .env
fi

# Check if modules are specified
if [ -z "$1" ]; then
    echo -e "${RED}No modules specified. Usage: $0 module1,module2,module3${NC}"
    exit 1
fi

MODULES=$1

echo -e "${BLUE}Installing Odoo modules: ${MODULES}${NC}"

# Run Odoo with the update flag
docker exec -it odoo-app odoo -u "$MODULES" -d "$POSTGRES_DB"

echo -e "${GREEN}Module installation complete!${NC}"
echo -e "${BLUE}You can now access the updated modules in Odoo.${NC}"