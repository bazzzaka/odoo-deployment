#!/bin/bash

set -e

# Set the postgres database host, port, user and password according to environment variables
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}
: ${ADMIN_PASSWORD:='admin'}

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then       
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" |cut -d " " -f3|sed 's/["\n\r]//g')
    fi;
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}

# Set Odoo config parameters
export ODOO_RC=/etc/odoo/odoo.conf
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"
check_config "admin_passwd" "$ADMIN_PASSWORD"

echo "Waiting for database to be ready..."
# Wait for PostgreSQL to be available
max_retries=30
retries=0
until PGPASSWORD=$PASSWORD psql -h $HOST -p $PORT -U $USER -d postgres -c "SELECT 1" > /dev/null 2>&1; do
    retries=$((retries+1))
    if [ $retries -ge $max_retries ]; then
        echo "Error: Could not connect to PostgreSQL after $max_retries attempts"
        exit 1
    fi
    echo "PostgreSQL is unavailable - sleeping 1 second..."
    sleep 1
done

echo "PostgreSQL is up - executing command"

# Initialize Odoo database if it doesn't exist
if ! PGPASSWORD=$PASSWORD psql -h $HOST -p $PORT -U $USER -c '\l' | grep -q $POSTGRES_DB; then
    echo "Initializing Odoo database..."
    DB_ARGS+=("--init=base")
    DB_ARGS+=("--database=$POSTGRES_DB")
    DB_ARGS+=("--without-demo=all")
else
    echo "Database already exists, skipping initialization"
fi

case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec odoo "$@"
        else
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac