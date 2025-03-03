#!/bin/bash

# Script to setup automated database backups for Odoo
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Source env file
if [ -f "$BASE_DIR/.env" ]; then
    source "$BASE_DIR/.env"
else
    echo -e "${RED}No .env file found. Please create one from the template.${NC}"
    exit 1
fi

# Create backup script
echo -e "${BLUE}Creating backup script...${NC}"
cat > "$BASE_DIR/scripts/backup_database.sh" << EOF
#!/bin/bash

# Database backup script for Odoo

# Load environment variables
source $BASE_DIR/.env

# Create timestamp
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BASE_DIR/data/backups"
BACKUP_FILE="\$BACKUP_DIR/\$POSTGRES_DB-\$TIMESTAMP.sql"
LOG_FILE="$BASE_DIR/logs/backup.log"

# Ensure backup directory exists
mkdir -p "\$BACKUP_DIR"
mkdir -p "$BASE_DIR/logs"

# Log function
log() {
    echo "\$(date +"%Y-%m-%d %H:%M:%S") - \$1" >> "\$LOG_FILE"
    echo "\$1"
}

# Perform backup
log "Starting backup of \$POSTGRES_DB database..."
docker exec odoo-db pg_dump -U \$POSTGRES_USER \$POSTGRES_DB > "\$BACKUP_FILE"
if [ \$? -eq 0 ]; then
    log "Backup completed successfully: \$BACKUP_FILE"
    
    # Compress the backup
    gzip "\$BACKUP_FILE"
    log "Backup compressed: \$BACKUP_FILE.gz"
    
    # Remove backups older than 30 days
    find "\$BACKUP_DIR" -name "*.gz" -type f -mtime +30 -delete
    log "Cleaned up old backups"
else
    log "Backup failed!"
fi
EOF

# Make backup script executable
chmod +x "$BASE_DIR/scripts/backup_database.sh"

# Setup crontab for daily backups
echo -e "${BLUE}Setting up cron job for daily backups...${NC}"
CRON_JOB="0 2 * * * $BASE_DIR/scripts/backup_database.sh > /dev/null 2>&1"

# Add to crontab if not already present
if ! (crontab -l 2>/dev/null | grep -q "$BASE_DIR/scripts/backup_database.sh"); then
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo -e "${GREEN}Cron job added for daily backups at 2 AM.${NC}"
else
    echo -e "${BLUE}Cron job already exists for backups.${NC}"
fi

# Create restore script
echo -e "${BLUE}Creating restore script...${NC}"
cat > "$BASE_DIR/scripts/restore_database.sh" << EOF
#!/bin/bash

# Database restore script for Odoo

# Load environment variables
source $BASE_DIR/.env

# Check if backup file is provided
if [ -z "\$1" ]; then
    echo "Usage: \$0 <backup_file>"
    echo "Available backups:"
    ls -la $BASE_DIR/data/backups/
    exit 1
fi

BACKUP_FILE="\$1"
LOG_FILE="$BASE_DIR/logs/restore.log"

# Log function
log() {
    echo "\$(date +"%Y-%m-%d %H:%M:%S") - \$1" >> "\$LOG_FILE"
    echo "\$1"
}

# Check if backup file exists
if [ ! -f "\$BACKUP_FILE" ]; then
    log "Backup file \$BACKUP_FILE does not exist!"
    exit 1
fi

# If file is compressed, uncompress it
if [[ "\$BACKUP_FILE" == *.gz ]]; then
    log "Uncompressing backup file..."
    gunzip -c "\$BACKUP_FILE" > "/tmp/odoo_restore.sql"
    BACKUP_FILE="/tmp/odoo_restore.sql"
fi

# Stop Odoo service
log "Stopping Odoo service..."
cd $BASE_DIR && docker compose stop odoo
log "Odoo service stopped"

# Restore database
log "Restoring database \$POSTGRES_DB..."
cat "\$BACKUP_FILE" | docker exec -i odoo-db psql -U \$POSTGRES_USER -d postgres -c "DROP DATABASE IF EXISTS \$POSTGRES_DB;"
cat "\$BACKUP_FILE" | docker exec -i odoo-db psql -U \$POSTGRES_USER -d postgres -c "CREATE DATABASE \$POSTGRES_DB OWNER \$POSTGRES_USER;"
cat "\$BACKUP_FILE" | docker exec -i odoo-db psql -U \$POSTGRES_USER \$POSTGRES_DB

if [ \$? -eq 0 ]; then
    log "Database restored successfully"
    
    # Cleanup temporary file if created
    if [[ "\$BACKUP_FILE" == "/tmp/odoo_restore.sql" ]]; then
        rm "\$BACKUP_FILE"
    fi
else
    log "Database restore failed!"
fi

# Start Odoo service
log "Starting Odoo service..."
cd $BASE_DIR && docker compose start odoo
log "Odoo service started"

log "Restore process completed"
EOF

# Make restore script executable
chmod +x "$BASE_DIR/scripts/restore_database.sh"

echo -e "${GREEN}Backup system setup completed!${NC}"
echo -e "${BLUE}Daily backups will run at 2 AM.${NC}"
echo -e "${BLUE}To restore a backup, run: $BASE_DIR/scripts/restore_database.sh <backup_file>${NC}"