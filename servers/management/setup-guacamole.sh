#!/usr/bin/env bash
set -e

POSTGRESQL_CONTAINER="postgresql"
ENV_FILE=".env"

# Check if .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found in $(pwd)"
    exit 1
fi

# Read values from .env and clean them
GUACAMOLE_DATABASE=$(grep  -E '^GUACAMOLE_DATABASE='  "$ENV_FILE" | cut -d '=' -f2- | xargs | tr -d '\r')
POSTGRES_USER=$(grep -E '^POSTGRES_USER=' "$ENV_FILE" | cut -d '=' -f2- | xargs | tr -d '\r')
POSTGRES_PASSWORD=$(grep -E '^POSTGRES_PASSWORD=' "$ENV_FILE" | cut -d '=' -f2- | xargs | tr -d '\r')

echo "✅ Found the following variables / values:"
echo "   - GUACAMOLE_DATABASE=$GUACAMOLE_DATABASE"
echo "   - POSTGRES_USER=$POSTGRES_USER"
echo "   - POSTGRES_PASSWORD=$POSTGRES_PASSWORD"

# Validate required vars
MISSING_VARS=()
[ -z "$GUACAMOLE_DATABASE" ]  && MISSING_VARS+=("GUACAMOLE_DATABASE")
[ -z "$POSTGRES_USER" ] && MISSING_VARS+=("POSTGRES_USER")
[ -z "$POSTGRES_PASSWORD" ] && MISSING_VARS+=("POSTGRES_PASSWORD")

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "❌ Error: The following required variables are missing or empty in $ENV_FILE:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    exit 1
fi

# Check if database exists
echo "🔍 Checking if database '$GUACAMOLE_DATABASE' already exists..."
if sudo docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRESQL_CONTAINER" \
    psql -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$GUACAMOLE_DATABASE';" | grep -q 1; then
    echo "✅ Database '$GUACAMOLE_DATABASE' already exists. Skipping creation."
    exit 0
fi

# Create the database
echo "📦 Creating database '$GUACAMOLE_DATABASE'..."
sudo docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRESQL_CONTAINER" \
    psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE \"$GUACAMOLE_DATABASE\";"

# Grant permissions to database
sudo docker exec -e PGPASSWORD="$ADMIN_PASSWORD" -i "$POSTGRESQL_CONTAINER" psql -U "$POSTGRES_USER" -d "$GUACAMOLE_DATABASE" <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$POSTGRES_USER') THEN
      CREATE USER "$POSTGRES_USER" WITH PASSWORD '$POSTGRES_PASSWORD';
   END IF;
END
\$\$;

GRANT CONNECT ON DATABASE "$GUACAMOLE_DATABASE" TO "$POSTGRES_USER";
GRANT USAGE ON SCHEMA public TO "$POSTGRES_USER";
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "$POSTGRES_USER";
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA public TO "$POSTGRES_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "$POSTGRES_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO "$POSTGRES_USER";
EOF

# Initialise the schema
echo "⚙️  Initialising Guacamole schema in '$GUACAMOLE_DATABASE'..."
sudo docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql | \
sudo docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" -i "$POSTGRESQL_CONTAINER" \
     psql -U "$POSTGRES_USER" -d "$GUACAMOLE_DATABASE"
echo "✅ Database '$GUACAMOLE_DATABASE' created and initialised successfully."

echo 
echo 
sudo docker exec postgresql psql -U "$POSTGRES_USER" -l
echo 
