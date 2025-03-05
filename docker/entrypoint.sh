#!/bin/bash

set -e

# Process the odoo.conf template with environment variables
if [ -f /etc/odoo/odoo.conf.template ]; then
    echo "Generating odoo.conf from template..."
    envsubst < /etc/odoo/odoo.conf.template > /etc/odoo/odoo.conf
    echo "Configuration file generated successfully"
fi

# Check for required environment variables
if [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ] || [ -z "$ADMIN_PASSWORD" ]; then
    echo "Error: Required environment variables are not set"
    echo "Please ensure POSTGRES_USER, POSTGRES_PASSWORD, and ADMIN_PASSWORD are defined in your .env file"
    exit 1
fi

# Set connection parameters safely
HOST=${DB_HOST:-"db"}  # Only non-sensitive values should have defaults
PORT=${DB_PORT:-5432}
USER=$POSTGRES_USER     # No default for sensitive values
PASSWORD=$POSTGRES_PASSWORD
: ${BUILD_ENV:='prod'}

# Function to check if a parameter exists in odoo.conf
function is_param_in_config() {
    local param=$1
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC"; then
        return 0
    else
        return 1
    fi
}

# Define database connection arguments for command line
DB_ARGS=()
function add_db_arg() {
    param="$1"
    value="$2"
    if is_param_in_config "$param"; then
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" | cut -d "=" -f2 | tr -d " \"'\r\n")
    fi
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}

# Add database connection parameters
add_db_arg "db_host" "$HOST"
add_db_arg "db_port" "$PORT"
add_db_arg "db_user" "$USER"
add_db_arg "db_password" "$PASSWORD"

# Create log directory if it doesn't exist
if [ ! -d /var/log/odoo ]; then
    mkdir -p /var/log/odoo
    chown -R odoo:odoo /var/log/odoo
fi

# Wait for PostgreSQL to be available (using the wait-for-psql script)
echo "Waiting for database to be ready..."
if ! wait-for-psql.py ${DB_ARGS[@]} --timeout=60; then
    echo "Database connection failure. Exiting."
    exit 1
fi
echo "Database is ready."

# Check if we're in dev mode
if [ "$BUILD_ENV" = "dev" ]; then
    echo "Running in development mode"
    # Enable extra development features
    DB_ARGS+=("--dev=all")
    # For debugging with VS Code, uncomment the following line:
    # DB_ARGS+=("--limit-time-real=10000")
fi

# Check if the database exists
DB_EXISTS=$(PGPASSWORD=$PASSWORD psql -h $HOST -p $PORT -U $USER -tAc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}'")

# Initialize database if it doesn't exist
if [ "$DB_EXISTS" != "1" ]; then
    echo "Initializing Odoo database '${POSTGRES_DB}'..."
    
    # Get modules to initialize from environment variable or use default
    MODULES_TO_INIT=${INIT_MODULES:-base}
    echo "Modules to initialize: ${MODULES_TO_INIT}"
    
    # Prepare database with basic structure
    DB_ARGS+=("--init=${MODULES_TO_INIT}")
    DB_ARGS+=("--database=${POSTGRES_DB}")
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
    echo "Database '${POSTGRES_DB}' already exists, skipping initialization"
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