#!/bin/bash

# Script per aggiornare automaticamente il DOCKER_GROUP nel file .env

ENV_FILE=".env"
DOCKER_GID=$(getent group docker | cut -d: -f3)

if [ -z "$DOCKER_GID" ]; then
    echo "Errore: Non riesco a trovare il gruppo docker"
    exit 1
fi

echo "Gruppo docker trovato con GID: $DOCKER_GID"

if grep -q "^DOCKER_GROUP=" "$ENV_FILE"; then
    sed -i "s/^DOCKER_GROUP=.*/DOCKER_GROUP=$DOCKER_GID/" "$ENV_FILE"
    echo "DOCKER_GROUP aggiornato a $DOCKER_GID nel file $ENV_FILE"
else
    echo "" >> "$ENV_FILE"
    echo "# Docker Group ID for Coder permissions" >> "$ENV_FILE"
    echo "DOCKER_GROUP=$DOCKER_GID" >> "$ENV_FILE"
    echo "DOCKER_GROUP=$DOCKER_GID aggiunto al file $ENV_FILE"
fi