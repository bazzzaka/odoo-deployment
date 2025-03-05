#!/bin/bash

# Automated Database Backup Script for Odoo

set -e

# Load environment variables
if [ -f .env ]; then
    source .env
fi

# Set default values if not defined in .env
POSTGRES_USER="${POSTGRES_USER:-odoo}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-odoo}"
POSTGRES_DB="${POSTGRES_DB:-odoo}"
BACKUP_DIR="${BACKUP_DIR:-./data/backups}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
DATE_FORMAT=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="${POSTGRES_DB}_${DATE_FORMAT}.dump"

# Ensure backup directory exists
mkdir -p "${BACKUP_DIR}"

# Log file
LOG_FILE="./logs/backup_${DATE_FORMAT}.log"
mkdir -p ./logs

# Log function
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "${LOG_FILE}"
}

log "Starting backup of ${POSTGRES_DB} database..."

# Create backup
if docker exec odoo-db pg_dump -U "${POSTGRES_USER}" "${POSTGRES_DB}" -F c > "${BACKUP_DIR}/${BACKUP_FILENAME}"; then
    log "Backup completed successfully: ${BACKUP_DIR}/${BACKUP_FILENAME}"
    
    # Compress the backup to save space
    gzip "${BACKUP_DIR}/${BACKUP_FILENAME}" && \
    log "Backup compressed: ${BACKUP_DIR}/${BACKUP_FILENAME}.gz"
    
    # Remove backups older than retention period
    if [ -n "${BACKUP_RETENTION_DAYS}" ] && [ "${BACKUP_RETENTION_DAYS}" -gt 0 ]; then
        log "Cleaning up backups older than ${BACKUP_RETENTION_DAYS} days..."
        find "${BACKUP_DIR}" -name "*.dump.gz" -type f -mtime +${BACKUP_RETENTION_DAYS} -delete
        find "${BACKUP_DIR}" -name "*.dump" -type f -mtime +${BACKUP_RETENTION_DAYS} -delete
        log "Cleanup completed"
    fi
else
    log "ERROR: Backup failed!"
    exit 1
fi

log "Backup process completed successfully"