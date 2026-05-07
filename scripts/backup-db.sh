#!/usr/bin/env bash
set -euo pipefail

APP_SLUG="__APP_SLUG__"
BACKUP_DIR="./backup"

mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/${APP_SLUG}_db-${TIMESTAMP}.sql.gz"

echo "→ Backup de la base PostgreSQL vers : $BACKUP_FILE"

docker compose \
  --env-file .env \
  --env-file .env.local \
  -f "docker-compose.${APP_ENV:-dev}.yml" \
  exec -T db \
  pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" \
  | gzip > "$BACKUP_FILE"

echo "✔ Backup terminé : $BACKUP_FILE"