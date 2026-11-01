#!/usr/bin/env bash
set -e

# Provisions Semaphore with the ansible/ folder of this repo (via the REST API).
# Safe to re-run: existing resources (matched by name) are left untouched.

ENV_FILE=".env"
SEMAPHORE_URL="${SEMAPHORE_URL:-http://localhost:3001}"
SSH_KEY_FILE="${SSH_KEY_FILE:-$HOME/.ssh/id_ed25519_semaphore}"  # private key Semaphore uses to reach the servers
SSH_LOGIN="${SSH_LOGIN:-vflorio}"

PROJECT_NAME="homelab"
GIT_URL="https://github.com/vflorio/home-lab.git"
GIT_BRANCH="main"
INVENTORY_FILE="ansible/inventory.ini"  # path inside the repository

# name|playbook|default hosts (empty = must be chosen at run time)
TEMPLATES=(
    "Update apt packages|ansible/playbooks/update-apt-packages.yml|servers"
    "Docker prune|ansible/playbooks/docker-prune.yml|servers"
    "Get disk usage|ansible/playbooks/get-disk-usage.yml|servers"
    "Install Docker|ansible/playbooks/install-docker.yml|"
    "Setup Traefik logrotate|ansible/playbooks/setup-traefik-logrotate.yml|gateway.intranet.vflorio.com"
)

# Check if .env and SSH key exist
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found in $(pwd)"
    exit 1
fi
if [ ! -f "$SSH_KEY_FILE" ]; then
    echo "❌ Error: SSH key $SSH_KEY_FILE not found"
    echo "   Generate it with: ssh-keygen -t ed25519 -N '' -C semaphore -f $SSH_KEY_FILE"
    echo "   and add ${SSH_KEY_FILE}.pub to ~/.ssh/authorized_keys of every server."
    exit 1
fi

# Read values from .env and clean them
SEMAPHORE_ADMIN_USER=$(grep -E '^SEMAPHORE_ADMIN_USER=' "$ENV_FILE" | cut -d '=' -f2- | xargs | tr -d '\r')
SEMAPHORE_ADMIN_PASSWORD=$(grep -E '^SEMAPHORE_ADMIN_PASSWORD=' "$ENV_FILE" | cut -d '=' -f2- | xargs | tr -d '\r')

if [ -z "$SEMAPHORE_ADMIN_USER" ] || [ -z "$SEMAPHORE_ADMIN_PASSWORD" ]; then
    echo "❌ Error: SEMAPHORE_ADMIN_USER and SEMAPHORE_ADMIN_PASSWORD must be set in $ENV_FILE"
    exit 1
fi

# Login (session cookie)
COOKIE_JAR=$(mktemp)
trap 'rm -f "$COOKIE_JAR"' EXIT

curl -sf -c "$COOKIE_JAR" -H "Content-Type: application/json" \
    -d "$(jq -n --arg u "$SEMAPHORE_ADMIN_USER" --arg p "$SEMAPHORE_ADMIN_PASSWORD" '{auth: $u, password: $p}')" \
    "$SEMAPHORE_URL/api/auth/login" > /dev/null \
    || { echo "❌ Error: login to $SEMAPHORE_URL as '$SEMAPHORE_ADMIN_USER' failed"; exit 1; }

api() {  # api METHOD PATH [JSON]
    curl -sf -b "$COOKIE_JAR" -X "$1" -H "Content-Type: application/json" ${3:+-d "$3"} "$SEMAPHORE_URL/api$2"
}

# ensure PATH NAME JSON -> prints the id of the resource called NAME, creating it if missing
ensure() {
    local id
    id=$(api GET "$1" | jq -r --arg n "$2" 'first(.[] | select(.name == $n) | .id) // empty')
    if [ -n "$id" ]; then
        echo "   = $2" >&2
    else
        id=$(api POST "$1" "$3" | jq -r '.id')
        echo "   + $2" >&2
    fi
    echo "$id"
}

echo "⚙️  Provisioning Semaphore at $SEMAPHORE_URL..."

PROJECT_ID=$(ensure /projects "$PROJECT_NAME" "$(jq -n --arg n "$PROJECT_NAME" '{name: $n}')")
P="/project/$PROJECT_ID"

NONE_KEY_ID=$(ensure "$P/keys" "none" "$(jq -n --argjson p "$PROJECT_ID" \
    '{project_id: $p, name: "none", type: "none"}')")

SSH_KEY_ID=$(ensure "$P/keys" "ssh-$SSH_LOGIN" "$(jq -n --argjson p "$PROJECT_ID" --arg l "$SSH_LOGIN" --rawfile k "$SSH_KEY_FILE" \
    '{project_id: $p, name: ("ssh-" + $l), type: "ssh", ssh: {login: $l, private_key: $k}}')")

REPOSITORY_ID=$(ensure "$P/repositories" "home-lab" "$(jq -n --argjson p "$PROJECT_ID" --argjson k "$NONE_KEY_ID" \
    --arg u "$GIT_URL" --arg b "$GIT_BRANCH" \
    '{project_id: $p, name: "home-lab", git_url: $u, git_branch: $b, ssh_key_id: $k}')")

INVENTORY_ID=$(ensure "$P/inventory" "servers" "$(jq -n --argjson p "$PROJECT_ID" --argjson k "$SSH_KEY_ID" \
    --argjson r "$REPOSITORY_ID" --arg f "$INVENTORY_FILE" \
    '{project_id: $p, name: "servers", type: "file", inventory: $f, repository_id: $r, ssh_key_id: $k}')")

# ansible/ansible.cfg is not picked up (playbooks run from the repo root), so mirror it here
ENVIRONMENT_ID=$(ensure "$P/environment" "default" "$(jq -n --argjson p "$PROJECT_ID" \
    '{project_id: $p, name: "default", json: "{}",
      env: ({ANSIBLE_HOST_KEY_CHECKING: "False", ANSIBLE_PIPELINING: "True", ANSIBLE_TIMEOUT: "60"} | tojson)}')")

for entry in "${TEMPLATES[@]}"; do
    IFS='|' read -r name playbook hosts <<< "$entry"
    ensure "$P/templates" "$name" "$(jq -n --argjson p "$PROJECT_ID" --argjson i "$INVENTORY_ID" \
        --argjson r "$REPOSITORY_ID" --argjson e "$ENVIRONMENT_ID" \
        --arg n "$name" --arg pb "$playbook" --arg h "$hosts" \
        '{project_id: $p, name: $n, app: "ansible", playbook: $pb,
          inventory_id: $i, repository_id: $r, environment_id: $e,
          survey_vars: [{name: "hosts", title: "Hosts (group or hostname)", required: true, type: "", default_value: $h}]}')" > /dev/null
done

echo "✅ Semaphore provisioned: project '$PROJECT_NAME' (id $PROJECT_ID)."
