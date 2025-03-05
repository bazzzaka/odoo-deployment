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
INIT_MODULES=${INIT_MODULES:-base,web}

# Fix directory permissions (as root)
echo "Setting up proper permissions for Odoo directories..."
mkdir -p /var/lib/odoo/filestore
mkdir -p /var/lib/odoo/sessions
mkdir -p /var/lib/odoo/addons
mkdir -p /var/log/odoo
mkdir -p /mnt/extra-addons

# Ensure odoo user has full access to required directories
chown -R odoo:odoo /var/lib/odoo
chown -R odoo:odoo /mnt/extra-addons
chown -R odoo:odoo /var/log/odoo
chown -R odoo:odoo /etc/odoo

# Set proper permissions
chmod -R 755 /var/lib/odoo
chmod -R 755 /mnt/extra-addons

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

EOF
echo "Configuration file created successfully"
chown odoo:odoo /etc/odoo/odoo.conf
chmod 644 /etc/odoo/odoo.conf

# Set the default config file
export ODOO_RC=/etc/odoo/odoo.conf

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
# Store them in an environment variable to avoid complex passing between processes
DB_ARGS="--db_host=$DB_HOST --db_port=$DB_PORT --db_user=$DB_USER --db_password=$DB_PASSWORD"

# Check if we're in dev mode
if [ "$BUILD_ENV" = "dev" ]; then
    echo "Running in development mode"
    # Enable extra development features
    DB_ARGS="$DB_ARGS --dev=all"
fi

# Check if the database exists 
DB_EXISTS=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'")

if [ "$DB_EXISTS" != "1" ]; then
    echo "Database '${DB_NAME}' does not exist. Creating it now..."
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER} TEMPLATE template0 ENCODING 'UTF8';" postgres
    echo "Database created successfully. Will initialize with modules: $INIT_MODULES"
    
    # Flag to indicate that we need to initialize the database
    DB_NEEDS_INIT=true
else
    # Check if database has Odoo tables already
    TABLES_EXIST=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -tAc "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='ir_module_module')" $DB_NAME 2>/dev/null || echo "f")
    
    if [ "$TABLES_EXIST" != "t" ]; then
        echo "Database exists but has no Odoo tables. Will initialize with modules: $INIT_MODULES"
        DB_NEEDS_INIT=true
    else
        echo "Database already initialized with Odoo tables."
        DB_NEEDS_INIT=false
    fi
fi

# Function to create a runas script - we'll use this to avoid problems with the user's shell
create_runas_script() {
    local SCRIPT_CONTENT="$1"
    local SCRIPT_PATH="/tmp/odoo_runas_script.sh"
    
    echo "#!/bin/bash" > $SCRIPT_PATH
    echo "$SCRIPT_CONTENT" >> $SCRIPT_PATH
    chmod +x $SCRIPT_PATH
    chown odoo:odoo $SCRIPT_PATH
    
    echo $SCRIPT_PATH
}

# Prepare the actual command
get_odoo_command() {
    local CMD="$1"
    shift
    local ARGS="$@"
    echo "cd /var/lib/odoo && PATH=\"$PATH\" exec $CMD $ARGS"
}

# Process the command
case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]]; then
            CMD=$(get_odoo_command "odoo" "scaffold" "$@")
            SCRIPT=$(create_runas_script "$CMD")
            exec runuser -u odoo $SCRIPT
        elif [ "$DB_NEEDS_INIT" = true ]; then
            echo "Initializing database with modules: $INIT_MODULES"
            echo "This may take a few minutes..."
            
            # Run Odoo with module initialization
            INIT_CMD=$(get_odoo_command "odoo" "$DB_ARGS --init=$INIT_MODULES --database=$DB_NAME --without-demo=${WITHOUT_DEMO:-all} --stop-after-init")
            INIT_SCRIPT=$(create_runas_script "$INIT_CMD")
            runuser -u odoo $INIT_SCRIPT
            
            echo "Module initialization completed, starting Odoo server..."
            ODOO_CMD=$(get_odoo_command "odoo" "$* $DB_ARGS")
            ODOO_SCRIPT=$(create_runas_script "$ODOO_CMD")
            exec runuser -u odoo $ODOO_SCRIPT
        else
            echo "Starting Odoo server..."
            ODOO_CMD=$(get_odoo_command "odoo" "$* $DB_ARGS")
            ODOO_SCRIPT=$(create_runas_script "$ODOO_CMD")
            exec runuser -u odoo $ODOO_SCRIPT
        fi
        ;;
    -*)
        echo "Starting Odoo server with custom options..."
        ODOO_CMD=$(get_odoo_command "odoo" "$* $DB_ARGS")
        ODOO_SCRIPT=$(create_runas_script "$ODOO_CMD")
        exec runuser -u odoo $ODOO_SCRIPT
        ;;
    *)
        echo "Executing custom command: $@"
        CUSTOM_CMD=$(get_odoo_command "$@")
        CUSTOM_SCRIPT=$(create_runas_script "$CUSTOM_CMD")
        exec runuser -u odoo $CUSTOM_SCRIPT
esac