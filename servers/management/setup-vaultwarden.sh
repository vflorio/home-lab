#!/usr/bin/env bash
# Creates the Vaultwarden role and database on the shared PostgreSQL.
# Run from ~/management before the first `docker compose up -d vaultwarden`; safe to re-run.
set -e

POSTGRESQL_CONTAINER="postgresql"
ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found in $(pwd)"
    exit 1
fi

env_value() { grep -E "^$1=" "$ENV_FILE" | cut -d '=' -f2- | sed 's/ #.*//' | xargs | tr -d '\r'; }

POSTGRES_USER=$(env_value POSTGRES_USER)
POSTGRES_PASSWORD=$(env_value POSTGRES_PASSWORD)
VAULTWARDEN_DATABASE=$(env_value VAULTWARDEN_DATABASE)
VAULTWARDEN_DB_USER=$(env_value VAULTWARDEN_DB_USER)
VAULTWARDEN_DB_PASSWORD=$(env_value VAULTWARDEN_DB_PASSWORD)

MISSING_VARS=()
for var in POSTGRES_USER POSTGRES_PASSWORD VAULTWARDEN_DATABASE VAULTWARDEN_DB_USER VAULTWARDEN_DB_PASSWORD; do
    [ -z "${!var}" ] && MISSING_VARS+=("$var")
done
if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "❌ Error: missing or empty in $ENV_FILE: ${MISSING_VARS[*]}"
    exit 1
fi

psql_admin() {
    sudo docker exec -i -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRESQL_CONTAINER" \
        psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres "$@"
}

echo "👤 Creating/updating role '$VAULTWARDEN_DB_USER'..."
psql_admin <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$VAULTWARDEN_DB_USER') THEN
      CREATE ROLE "$VAULTWARDEN_DB_USER" LOGIN PASSWORD '$VAULTWARDEN_DB_PASSWORD';
   ELSE
      ALTER ROLE "$VAULTWARDEN_DB_USER" LOGIN PASSWORD '$VAULTWARDEN_DB_PASSWORD';
   END IF;
END
\$\$;
EOF

if psql_admin -tAc "SELECT 1 FROM pg_database WHERE datname = '$VAULTWARDEN_DATABASE';" | grep -q 1; then
    echo "✅ Database '$VAULTWARDEN_DATABASE' already exists. Skipping creation."
else
    echo "📦 Creating database '$VAULTWARDEN_DATABASE'..."
    psql_admin -c "CREATE DATABASE \"$VAULTWARDEN_DATABASE\" OWNER \"$VAULTWARDEN_DB_USER\";"
fi

echo "✅ Done. Start it with: docker compose up -d vaultwarden"
