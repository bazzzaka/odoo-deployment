#!/bin/bash

set -e

# Check for required environment variables
if [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ] || [ -z "$ADMIN_PASSWORD" ]; then
    echo "Error: Required environment variables are not set"
    echo "Please ensure POSTGRES_USER, POSTGRES_PASSWORD, and ADMIN_PASSWORD are defined in your .env file"
    exit 1
fi

# Set connection parameters
DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-5432}
DB_USER=$POSTGRES_USER
DB_PASSWORD=$POSTGRES_PASSWORD
DB_NAME=${POSTGRES_DB:-odoo}
BUILD_ENV=${BUILD_ENV:-prod}

# Create a fresh odoo.conf with explicit values (not relying on envsubst)
echo "Creating Odoo configuration file with explicit values..."
cat > /etc/odoo/odoo.conf << EOF
[options]
; This is the password that allows database operations:
admin_passwd = $ADMIN_PASSWORD

; Database settings
db_host = $DB_HOST
db_port = $DB_PORT
db_user = $DB_USER
db_password = $DB_PASSWORD
db_name = $DB_NAME
db_template = template0
db_maxconn = 64

; Addons settings
addons_path = /mnt/extra-addons,/usr/lib/python3/dist-packages/odoo/addons

; Worker settings - adapt based on server resources
workers = ${WORKERS:-2}
max_cron_threads = ${CRON_WORKERS:-1}

; Performance tuning
limit_memory_soft = ${MEMORY_SOFT:-2147483648}
limit_memory_hard = ${MEMORY_HARD:-2684354560}
limit_request = 8192
limit_time_cpu = ${CPU_LIMIT:-60}
limit_time_real = ${REAL_LIMIT:-120}

; Data handling
data_dir = /var/lib/odoo
list_db = ${LIST_DB:-True}
log_db = False
proxy_mode = True
without_demo = ${WITHOUT_DEMO:-True}

; Logging settings
logfile = /var/log/odoo/odoo-server.log
log_level = ${LOG_LEVEL:-info}
log_handler = [':INFO']
logrotate = True

; Longpolling settings
longpolling_port = 8072

; Security settings
xmlrpc = True
xmlrpc_interface = 
xmlrpc_port = 8069
xmlrpcs = True
xmlrpcs_interface = 
xmlrpcs_port = 8071

; Server-wide modules
server_wide_modules = base,web
EOF

echo "Configuration file created successfully"

# Set the default config file
export ODOO_RC=/etc/odoo/odoo.conf

# Create log directory if it doesn't exist
if [ ! -d /var/log/odoo ]; then
    mkdir -p /var/log/odoo
    chown -R odoo:odoo /var/log/odoo
fi

# Display the database configuration for debugging
echo "Database configuration:"
echo "Host: $DB_HOST"
echo "Port: $DB_PORT"
echo "User: $DB_USER"
echo "Database: $DB_NAME"

# Wait for PostgreSQL to be available
echo "Waiting for database to be ready..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    echo "Attempt $attempt: Connecting to PostgreSQL..."
    if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "SELECT 1" >/dev/null 2>&1; then
        echo "Database connection successful!"
        break
    else
        echo "Could not connect to database, retrying in 2 seconds..."
        attempt=$((attempt+1))
        sleep 2
    fi
    
    if [ $attempt -gt $max_attempts ]; then
        echo "Failed to connect to database after $max_attempts attempts. Exiting."
        exit 1
    fi
done

# Define database connection arguments for command line
DB_ARGS=()
DB_ARGS+=("--db_host")
DB_ARGS+=("$DB_HOST")
DB_ARGS+=("--db_port")
DB_ARGS+=("$DB_PORT")
DB_ARGS+=("--db_user")
DB_ARGS+=("$DB_USER")
DB_ARGS+=("--db_password")
DB_ARGS+=("$DB_PASSWORD")

# Check if we're in dev mode
if [ "$BUILD_ENV" = "dev" ]; then
    echo "Running in development mode"
    # Enable extra development features
    DB_ARGS+=("--dev=all")
fi

# Check if the database exists
DB_EXISTS=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'")

# Initialize database if it doesn't exist
if [ "$DB_EXISTS" != "1" ]; then
    echo "Initializing Odoo database '${DB_NAME}'..."
    
    # Get modules to initialize from environment variable or use default
    MODULES_TO_INIT=${INIT_MODULES:-base}
    echo "Modules to initialize: ${MODULES_TO_INIT}"
    
    # Add initialization parameters
    DB_ARGS+=("--init=${MODULES_TO_INIT}")
    DB_ARGS+=("--database=${DB_NAME}")
    DB_ARGS+=("--without-demo=${WITHOUT_DEMO:-all}")
    
    # Create the database and install initial modules
    echo "Running initial module installation..."
    odoo "${DB_ARGS[@]}"
    
    echo "Database initialization completed"
    
    # Remove the initialization flags for normal startup
    # We need to recreate the array to properly remove the init parameter
    NEW_DB_ARGS=()
    for arg in "${DB_ARGS[@]}"; do
        if [[ "$arg" != "--init=${MODULES_TO_INIT}" && "$arg" != "--without-demo=${WITHOUT_DEMO:-all}" ]]; then
            NEW_DB_ARGS+=("$arg")
        fi
    done
    DB_ARGS=("${NEW_DB_ARGS[@]}")
    
    echo "Continuing with normal startup..."
else
    echo "Database '${DB_NAME}' already exists, skipping initialization"
fi

# Process the command
case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]]; then
            exec odoo "$@"
        else
            echo "Starting Odoo server..."
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        echo "Starting Odoo server with custom options..."
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        echo "Executing custom command: $@"
        exec "$@"
esac