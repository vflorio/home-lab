#!/usr/bin/env bash
set -e

POSTGRESQL_CONTAINER="nextcloud-postgresql"
ENV_FILE=".env"

# Check if .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found in $(pwd)"
    exit 1
fi

# Read values from .env and clean them
NEXTCLOUD_DATABASE=$(grep  -E '^NEXTCLOUD_DATABASE='  "$ENV_FILE" | cut -d '=' -f2- | xargs | tr -d '\r')
POSTGRES_USER=$(grep -E '^POSTGRES_USER=' "$ENV_FILE" | cut -d '=' -f2- | xargs | tr -d '\r')
POSTGRES_PASSWORD=$(grep -E '^POSTGRES_PASSWORD=' "$ENV_FILE" | cut -d '=' -f2- | xargs | tr -d '\r')


# Check if database exists
echo "🔍 Checking if database '$NEXTCLOUD_DATABASE' already exists..."
if sudo docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRESQL_CONTAINER" \
    psql -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$NEXTCLOUD_DATABASE';" | grep -q 1; then
    echo "✅ Database '$NEXTCLOUD_DATABASE' exists, securing with permissions."
else
    echo "❌ Error: Database '$NEXTCLOUD_DATABASE' not found in container '$POSTGRESQL_CONTAINER'."
    exit 1
fi

# Grant permissions to database
sudo docker exec -e PGPASSWORD="$ADMIN_PASSWORD" -i "$POSTGRESQL_CONTAINER" psql -U "$POSTGRES_USER" -d "$NEXTCLOUD_DATABASE" <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$POSTGRES_USER') THEN
      CREATE USER "$POSTGRES_USER" WITH PASSWORD '$POSTGRES_PASSWORD';
   END IF;
END
\$\$;

GRANT CONNECT ON DATABASE "$NEXTCLOUD_DATABASE" TO "$POSTGRES_USER";
GRANT USAGE ON SCHEMA public TO "$POSTGRES_USER";
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "$POSTGRES_USER";
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA public TO "$POSTGRES_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "$POSTGRES_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO "$POSTGRES_USER";
EOF

echo 
echo 
sudo docker exec $POSTGRESQL_CONTAINER psql -U "$POSTGRES_USER" -l
echo 
