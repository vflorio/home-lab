#!/usr/bin/env bash
set -e

POSTGRESQL_CONTAINER="postgresql"
ENV_FILE=".env"
SQL_FILE="guacamole/connections.sql"
GUACAMOLE_USER="${GUACAMOLE_USER:-guacadmin}"

# Check if .env and SQL file exist
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found in $(pwd)"
    exit 1
fi
if [ ! -f "$SQL_FILE" ]; then
    echo "❌ Error: $SQL_FILE not found in $(pwd)"
    exit 1
fi

# Read values from .env and clean them
GUACAMOLE_DATABASE=$(grep -E '^GUACAMOLE_DATABASE=' "$ENV_FILE" | cut -d '=' -f2- | xargs | tr -d '\r')
POSTGRES_USER=$(grep -E '^POSTGRES_USER=' "$ENV_FILE" | cut -d '=' -f2- | xargs | tr -d '\r')
POSTGRES_PASSWORD=$(grep -E '^POSTGRES_PASSWORD=' "$ENV_FILE" | cut -d '=' -f2- | xargs | tr -d '\r')

# Validate required vars
MISSING_VARS=()
[ -z "$GUACAMOLE_DATABASE" ] && MISSING_VARS+=("GUACAMOLE_DATABASE")
[ -z "$POSTGRES_USER" ] && MISSING_VARS+=("POSTGRES_USER")
[ -z "$POSTGRES_PASSWORD" ] && MISSING_VARS+=("POSTGRES_PASSWORD")

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "❌ Error: The following required variables are missing or empty in $ENV_FILE:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    exit 1
fi

# Apply connections
echo "⚙️  Applying $SQL_FILE to '$GUACAMOLE_DATABASE' (READ granted to '$GUACAMOLE_USER')..."
sudo docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" -i "$POSTGRESQL_CONTAINER" \
    psql -U "$POSTGRES_USER" -d "$GUACAMOLE_DATABASE" -v ON_ERROR_STOP=1 -v guac_user="$GUACAMOLE_USER" \
    < "$SQL_FILE"

echo
sudo docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRESQL_CONTAINER" \
    psql -U "$POSTGRES_USER" -d "$GUACAMOLE_DATABASE" \
    -c "SELECT connection_id, connection_name, protocol FROM guacamole_connection ORDER BY connection_name;"
echo "✅ Guacamole connections applied."
