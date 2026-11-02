#!/usr/bin/env bash
# Rotates the TSIG key used by Terraform (dynamic updates) and rndc.
# Run from the workstation, in dns/bind9; safe to re-run (every run makes a new key).
# Writes the new key to config/named.conf.key (gitignored) and terraform/terraform.tfvars,
# uploads it to the DNS server and restarts bind9.
set -e

DNS_HOST="vflorio@192.168.1.150"
REMOTE_DIR="~/bind9"
KEY_FILE="config/named.conf.key"
TFVARS_FILE="terraform/terraform.tfvars"

cd "$(dirname "$0")"

if [ ! -f "$TFVARS_FILE" ]; then
    echo "❌ Error: $TFVARS_FILE not found in $(pwd)"
    exit 1
fi

SECRET=$(openssl rand -base64 32)

echo "🔑 Writing new key to $KEY_FILE..."
umask 077
cat > "$KEY_FILE" <<EOF
key "tsig-key" {
        algorithm hmac-sha256;
        secret "$SECRET";
};
EOF
chmod 600 "$KEY_FILE"

echo "📤 Uploading key to $DNS_HOST..."
ssh "$DNS_HOST" "cd $REMOTE_DIR/config && sudo cp -p named.conf.key named.conf.key.bak-\$(date +%Y%m%d%H%M) && sudo chmod 600 named.conf.key.bak-* && sudo tee named.conf.key.new >/dev/null && sudo chown 0:0 named.conf.key.new && sudo chmod 600 named.conf.key.new && sudo mv named.conf.key.new named.conf.key" < "$KEY_FILE"

echo "🔄 Restarting bind9..."
ssh "$DNS_HOST" "cd $REMOTE_DIR && sudo docker exec dns named-checkconf /etc/bind/named.conf && sudo docker compose restart bind9 >/dev/null && sleep 3"

# rndc.conf includes named.conf.key, so rndc only works if named loaded the new key
echo "🔍 Verifying..."
if ! ssh "$DNS_HOST" "sudo docker exec dns rndc status >/dev/null"; then
    echo "❌ Error: rndc status failed, check 'sudo docker logs dns' on $DNS_HOST (backup in $REMOTE_DIR/config)"
    exit 1
fi

echo "📝 Updating TSIG_KEY_HOME in $TFVARS_FILE..."
sed -i -E "s|^TSIG_KEY_HOME *=.*|TSIG_KEY_HOME = \"$SECRET\"|" "$TFVARS_FILE"

echo "✅ TSIG key rotated. Check with: cd terraform && terraform plan"
