#!/usr/bin/env bash
# Installs the user_oidc app and points it at Authentik (provider in
# servers/gateway/authentik/blueprints/cloud-oidc.yaml).
# Run from ~/cloud after `docker compose up -d nextcloud`; safe to re-run (the provider is upserted).
set -e

NEXTCLOUD_CONTAINER="nextcloud"
ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found in $(pwd)"
    exit 1
fi

env_value() { grep -E "^$1=" "$ENV_FILE" | cut -d '=' -f2- | sed 's/ #.*//' | xargs | tr -d '\r'; }

GATEWAY_INTRANET_DOMAIN=$(env_value GATEWAY_INTRANET_DOMAIN)
NEXTCLOUD_OIDC_CLIENT_SECRET=$(env_value NEXTCLOUD_OIDC_CLIENT_SECRET)

MISSING_VARS=()
for var in GATEWAY_INTRANET_DOMAIN NEXTCLOUD_OIDC_CLIENT_SECRET; do
    [ -z "${!var}" ] && MISSING_VARS+=("$var")
done
if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "❌ Error: missing or empty in $ENV_FILE: ${MISSING_VARS[*]}"
    exit 1
fi

occ() { sudo docker exec -u www-data "$NEXTCLOUD_CONTAINER" php occ "$@"; }

echo "📦 Installing/enabling user_oidc..."
occ app:install user_oidc 2>/dev/null || occ app:enable user_oidc

# uid = Authentik username, not a hash: with soft_auto_provision (default on) the first
# Authentik login reuses the existing local account with the same name instead of creating a new one
echo "🔑 Creating/updating the Authentik provider..."
occ user_oidc:provider Authentik \
    --clientid=nextcloud \
    --clientsecret="$NEXTCLOUD_OIDC_CLIENT_SECRET" \
    --discoveryuri="https://auth.$GATEWAY_INTRANET_DOMAIN/application/o/nextcloud/.well-known/openid-configuration" \
    --scope="openid email profile" \
    --unique-uid=0 \
    --mapping-uid=preferred_username \
    --mapping-display-name=name \
    --mapping-email=email

echo "✅ Done. The login page now shows \"Accedi con Authentik\", local login still works."
