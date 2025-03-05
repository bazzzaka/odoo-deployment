#!/bin/bash

# Setup script for automated backups using cron

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up automated backups...${NC}"

# Ensure backup script is executable
chmod +x "${SCRIPT_DIR}/backup.sh"

# Define the cron job (daily at 2 AM)
CRON_JOB="0 2 * * * cd ${BASE_DIR} && ${SCRIPT_DIR}/backup.sh >> ${BASE_DIR}/logs/cron.log 2>&1"

# Add to crontab if not already present
if ! (crontab -l 2>/dev/null | grep -q "${SCRIPT_DIR}/backup.sh"); then
    (crontab -l 2>/dev/null || true; echo "$CRON_JOB") | crontab -
    echo -e "${GREEN}Cron job added for daily backups at 2 AM.${NC}"
else
    echo -e "${BLUE}Cron job already exists for backups.${NC}"
fi

# Create directory for logs if it doesn't exist
mkdir -p "${BASE_DIR}/logs"

echo -e "${GREEN}Automated backup setup completed!${NC}"
echo -e "${BLUE}Daily backups will run at 2 AM.${NC}"
echo -e "${BLUE}Backup files will be stored in ${BASE_DIR}/data/backups${NC}"
echo -e "${BLUE}Logs will be written to ${BASE_DIR}/logs/cron.log${NC}"