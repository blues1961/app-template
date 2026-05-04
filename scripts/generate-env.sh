#!/usr/bin/env bash
set -euo pipefail

TEMPLATE=".env.template"

[ -f "$TEMPLATE" ] || {
  echo "ERREUR: .env.template manquant"
  exit 1
}

# Charger template
set -a
source "$TEMPLATE"
set +a

# Validation minimale
[ -n "${APP_NAME:-}" ] || { echo "APP_NAME manquant"; exit 1; }
[ -n "${APP_SLUG:-}" ] || { echo "APP_SLUG manquant"; exit 1; }
[ -n "${APP_DEPOT:-}" ] || { echo "APP_DEPOT manquant"; exit 1; }
[ -n "${APP_NO:-}" ] || { echo "APP_NO manquant"; exit 1; }

# Génération automatique APP_HOST si vide
if [ -z "${APP_HOST:-}" ]; then
  APP_HOST="${APP_SLUG}.mon-site.ca"
fi

# Calcul ports
DEV_DB_PORT=$((5432 + APP_NO))
DEV_VITE_PORT=$((5173 + APP_NO))
DEV_API_PORT=$((8000 + APP_NO + 1))

# =========================
# .env.dev
# =========================
cat > .env.dev <<EOF
APP_ENV=dev

APP_NAME=$APP_NAME
APP_SLUG=$APP_SLUG
APP_DEPOT=$APP_DEPOT
APP_NO=$APP_NO

POSTGRES_USER=${APP_SLUG}_pg_user
POSTGRES_DB=${APP_SLUG}_pg_db

DEV_DB_PORT=$DEV_DB_PORT
DEV_VITE_PORT=$DEV_VITE_PORT
DEV_API_PORT=$DEV_API_PORT

VITE_API_BASE=${VITE_API_BASE:-/api}
EOF

echo "✔ .env.dev généré"

# =========================
# .env.prod
# =========================
cat > .env.prod <<EOF
APP_ENV=prod

APP_NAME=$APP_NAME
APP_SLUG=$APP_SLUG
APP_DEPOT=$APP_DEPOT
APP_NO=$APP_NO

APP_HOST=$APP_HOST

POSTGRES_USER=${APP_SLUG}_pg_user
POSTGRES_DB=${APP_SLUG}_pg_db

VITE_API_BASE=${VITE_API_BASE:-/api}
EOF

echo "✔ .env.prod généré"

# =========================
# .env.local
# =========================
if [ ! -f ".env.local" ]; then
cat > .env.local <<EOF
# --- Admin ---
ADMIN_USERNAME=${ADMIN_USERNAME:-}
ADMIN_EMAIL=${ADMIN_EMAIL:-}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-}

# --- Secrets (générés ensuite) ---
POSTGRES_PASSWORD=
DJANGO_SECRET_KEY=
EOF

echo "✔ .env.local créé"
else
  echo "• .env.local existe déjà (non modifié)"
fi

# Génération secrets si absents
./scripts/generate-secrets.sh

echo "✔ Environnement complet prêt"