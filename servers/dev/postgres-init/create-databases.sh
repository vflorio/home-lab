#!/bin/sh
# Runs only on the first init of an empty data directory (postgres docker entrypoint).
# POSTGRES_DB (coder) is created by the entrypoint itself, the others are created here.
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<SQL
CREATE DATABASE "$GITEA_DATABASE";
SQL
