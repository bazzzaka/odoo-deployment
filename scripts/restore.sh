#!/bin/bash

# Database Restoration Script for Odoo

set -e

# Load environment variables
if [ -f .env ]; then
    source .env
fi

# Set default values if not defined in .env
POSTGRES_USER="${POSTGRES_USER:-odoo}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-odoo}"
POSTGRES_DB="${POSTGRES_DB:-odoo}"
DATE_FORMAT=$(date +"%Y%m%d_%H%M%S")

# Log file
LOG_FILE="./logs/restore_${DATE_FORMAT}.log"
mkdir -p ./logs

# Log function
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "${LOG_FILE}"
}

# Check if backup file is provided
if [ -z "$1" ]; then
    log "ERROR: No backup file specified"
    echo "Usage: $0 <backup_file>"
    echo "Available backups:"
    find ./data/backups -type f -name "*.dump*" | sort
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "${BACKUP_FILE}" ]; then
    log "ERROR: Backup file ${BACKUP_FILE} does not exist"
    exit 1
fi

log "Starting database restoration from ${BACKUP_FILE}..."

# Stop Odoo service to prevent concurrent access
log "Stopping Odoo service..."
docker compose -f docker/docker-compose.yml stop odoo
log "Odoo service stopped"

# Prepare the backup file - decompress if needed
TEMP_FILE=""
if [[ "${BACKUP_FILE}" == *.gz ]]; then
    log "Decompressing backup file..."
    TEMP_FILE="/tmp/odoo_restore_${DATE_FORMAT}.dump"
    gunzip -c "${BACKUP_FILE}" > "${TEMP_FILE}"
    BACKUP_FILE="${TEMP_FILE}"
    log "Backup file decompressed"
fi

# Restore the database
log "Restoring database ${POSTGRES_DB}..."

# Check the format of the backup file
if [[ "${BACKUP_FILE}" == *.sql ]]; then
    # SQL format
    log "Detected SQL format backup"
    docker exec -i odoo-db psql -U "${POSTGRES_USER}" -c "DROP DATABASE IF EXISTS ${POSTGRES_DB};"
    docker exec -i odoo-db psql -U "${POSTGRES_USER}" -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};"
    docker exec -i odoo-db psql -U "${POSTGRES_USER}" "${POSTGRES_DB}" < "${BACKUP_FILE}"
elif [[ "${BACKUP_FILE}" == *.dump ]]; then
    # Custom format
    log "Detected custom format backup"
    docker exec -i odoo-db pg_restore -U "${POSTGRES_USER}" -d postgres -c --if-exists -C < "${BACKUP_FILE}"
else
    log "ERROR: Unknown backup format. Only .sql and .dump formats are supported"
    docker compose -f docker/docker-compose.yml start odoo
    if [ -n "${TEMP_FILE}" ] && [ -f "${TEMP_FILE}" ]; then
        rm "${TEMP_FILE}"
    fi
    exit 1
fi

# Clean up temporary file if created
if [ -n "${TEMP_FILE}" ] && [ -f "${TEMP_FILE}" ]; then
    rm "${TEMP_FILE}"
    log "Temporary file removed"
fi

# Start Odoo service
log "Starting Odoo service..."
docker compose -f docker/docker-compose.yml start odoo
log "Odoo service started"

log "Database restoration completed successfully"