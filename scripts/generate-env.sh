#!/usr/bin/env bash
set -euo pipefail

TEMPLATE=".env.template"

[ -f "$TEMPLATE" ] || {
  echo "ERREUR: .env.template manquant"
  echo "Copiez d'abord .env.template.example :"
  echo "  cp .env.template.example .env.template"
  exit 1
}

load_template() {
  local file="$1"
  local line key value

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|\#*)
        continue
        ;;
    esac

    key=${line%%=*}
    value=${line#*=}
    key=$(printf '%s' "$key" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    value=$(printf '%s' "$value" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

    if [ -n "$key" ]; then
      printf -v "$key" '%s' "$value"
      export "$key"
    fi
  done < "$file"
}

read_env_value() {
  local file="$1"
  local key="$2"

  if [ ! -f "$file" ]; then
    return
  fi

  sed -n "s/^${key}=//p" "$file" | tail -n 1
}

append_csv_value() {
  local list="${1:-}"
  local value="${2:-}"

  if [ -z "$value" ]; then
    printf '%s' "$list"
    return
  fi

  case ",$list," in
    *,"$value",*)
      printf '%s' "$list"
      ;;
    *)
      if [ -n "$list" ]; then
        printf '%s,%s' "$list" "$value"
      else
        printf '%s' "$value"
      fi
      ;;
  esac
}

ensure_local_key() {
  local key="$1"

  if ! grep -q "^${key}=" .env.local; then
    printf '%s=\n' "$key" >> .env.local
    echo "• .env.local complété avec ${key}"
  fi
}

normalize_app_depot() {
  local depot="$1"

  printf '%s' "$depot" \
    | tr '[:lower:]' '[:upper:]' \
    | sed 's/[^A-Z0-9]/_/g'
}

# Charger template
load_template "$TEMPLATE"

# Validation minimale
[ -n "${APP_NAME:-}" ] || { echo "APP_NAME manquant"; exit 1; }
[ -n "${APP_SLUG:-}" ] || { echo "APP_SLUG manquant"; exit 1; }
[ -n "${APP_DEPOT:-}" ] || { echo "APP_DEPOT manquant"; exit 1; }
[ -n "${APP_NO:-}" ] || { echo "APP_NO manquant"; exit 1; }

LOCAL_API_TOKEN_KEY="$(normalize_app_depot "$APP_DEPOT")_API_TOKEN"

APP_HOST_TEMPLATE="${APP_HOST:-}"

# Génération automatique APP_HOST si vide
if [ -z "$APP_HOST_TEMPLATE" ]; then
  APP_HOST_TEMPLATE="${APP_SLUG}.mon-site.ca"
fi

# Calcul ports
DEV_DB_PORT=$((5432 + APP_NO))
DEV_VITE_PORT=$((5173 + APP_NO))
DEV_API_PORT=$((8000 + APP_NO + 1))

APP_STACK=${APP_STACK:-$(read_env_value .env.dev APP_STACK)}
APP_STACK=${APP_STACK:-django-react-postgres}
BACKEND_FRAMEWORK=${BACKEND_FRAMEWORK:-$(read_env_value .env.dev BACKEND_FRAMEWORK)}
BACKEND_FRAMEWORK=${BACKEND_FRAMEWORK:-django}
FRONTEND_FRAMEWORK=${FRONTEND_FRAMEWORK:-$(read_env_value .env.dev FRONTEND_FRAMEWORK)}
FRONTEND_FRAMEWORK=${FRONTEND_FRAMEWORK:-react-vite}
DATABASE_ENGINE=${DATABASE_ENGINE:-$(read_env_value .env.dev DATABASE_ENGINE)}
DATABASE_ENGINE=${DATABASE_ENGINE:-postgres}
VITE_API_BASE=${VITE_API_BASE:-$(read_env_value .env.dev VITE_API_BASE)}
VITE_API_BASE=${VITE_API_BASE:-$(read_env_value .env.prod VITE_API_BASE)}
VITE_API_BASE=${VITE_API_BASE:-/api}

DEV_DJANGO_DEBUG=${DJANGO_DEBUG:-$(read_env_value .env.dev DJANGO_DEBUG)}
DEV_DJANGO_DEBUG=${DEV_DJANGO_DEBUG:-true}
PROD_DJANGO_DEBUG=false

DEV_DJANGO_ALLOWED_HOSTS=${DJANGO_ALLOWED_HOSTS:-$(read_env_value .env.dev DJANGO_ALLOWED_HOSTS)}
DEV_DJANGO_ALLOWED_HOSTS=${DEV_DJANGO_ALLOWED_HOSTS:-localhost,127.0.0.1}
DEV_DJANGO_ALLOWED_HOSTS=$(append_csv_value "$DEV_DJANGO_ALLOWED_HOSTS" "backend")
DEV_DJANGO_ALLOWED_HOSTS=$(append_csv_value "$DEV_DJANGO_ALLOWED_HOSTS" "0.0.0.0")

DEV_DJANGO_CSRF_TRUSTED_ORIGINS=${DJANGO_CSRF_TRUSTED_ORIGINS:-$(read_env_value .env.dev DJANGO_CSRF_TRUSTED_ORIGINS)}
DEV_DJANGO_CSRF_TRUSTED_ORIGINS=$(append_csv_value "$DEV_DJANGO_CSRF_TRUSTED_ORIGINS" "http://localhost:${DEV_VITE_PORT}")
DEV_DJANGO_CSRF_TRUSTED_ORIGINS=$(append_csv_value "$DEV_DJANGO_CSRF_TRUSTED_ORIGINS" "http://127.0.0.1:${DEV_VITE_PORT}")

PROD_DJANGO_ALLOWED_HOSTS=${DJANGO_ALLOWED_HOSTS:-$(read_env_value .env.prod DJANGO_ALLOWED_HOSTS)}
PROD_DJANGO_ALLOWED_HOSTS=$(append_csv_value "$PROD_DJANGO_ALLOWED_HOSTS" "$APP_HOST_TEMPLATE")
PROD_DJANGO_ALLOWED_HOSTS=$(append_csv_value "$PROD_DJANGO_ALLOWED_HOSTS" "backend")

PROD_DJANGO_CSRF_TRUSTED_ORIGINS=${DJANGO_CSRF_TRUSTED_ORIGINS:-$(read_env_value .env.prod DJANGO_CSRF_TRUSTED_ORIGINS)}
PROD_DJANGO_CSRF_TRUSTED_ORIGINS=$(append_csv_value "$PROD_DJANGO_CSRF_TRUSTED_ORIGINS" "https://${APP_HOST_TEMPLATE}")

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

VITE_API_BASE=$VITE_API_BASE

DJANGO_DEBUG=$DEV_DJANGO_DEBUG
DJANGO_ALLOWED_HOSTS=$DEV_DJANGO_ALLOWED_HOSTS
DJANGO_CSRF_TRUSTED_ORIGINS=$DEV_DJANGO_CSRF_TRUSTED_ORIGINS
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
APP_HOST=$APP_HOST_TEMPLATE

POSTGRES_USER=${APP_SLUG}_pg_user
POSTGRES_DB=${APP_SLUG}_pg_db

VITE_API_BASE=$VITE_API_BASE

DJANGO_DEBUG=$PROD_DJANGO_DEBUG
DJANGO_ALLOWED_HOSTS=$PROD_DJANGO_ALLOWED_HOSTS
DJANGO_CSRF_TRUSTED_ORIGINS=$PROD_DJANGO_CSRF_TRUSTED_ORIGINS
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

ensure_local_key "ADMIN_USERNAME"
ensure_local_key "ADMIN_EMAIL"
ensure_local_key "ADMIN_PASSWORD"
ensure_local_key "POSTGRES_PASSWORD"
ensure_local_key "DJANGO_SECRET_KEY"
ensure_local_key "$LOCAL_API_TOKEN_KEY"

# Génération secrets si absents
./scripts/generate-secrets.sh

echo "✔ Environnement complet prêt"
