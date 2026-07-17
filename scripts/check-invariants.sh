#!/usr/bin/env bash
set -euo pipefail

EXPECT_APPLICATION=0
if [ "${1:-}" = "--expect-application" ]; then
  EXPECT_APPLICATION=1
fi

fail() {
  echo "ERREUR: $1"
  exit 1
}

normalize_env_value() {
  local value="$1"

  case "$value" in
    \"*\")
      value="${value#\"}"
      value="${value%\"}"
      ;;
    \'*\')
      value="${value#\'}"
      value="${value%\'}"
      ;;
  esac

  printf '%s' "$value"
}

read_env_value() {
  local file="$1"
  local key="$2"
  local value

  if [ ! -f "$file" ]; then
    return
  fi

  value="$(sed -n "s/^${key}=//p" "$file" | tail -n 1)"
  normalize_env_value "$value"
}

assert_same_value() {
  local key="$1"
  local template_value dev_value prod_value

  template_value="$(read_env_value .env.template "$key")"
  dev_value="$(read_env_value .env.dev "$key")"
  prod_value="$(read_env_value .env.prod "$key")"

  [ -n "$template_value" ] || fail "$key est manquant dans .env.template"
  [ "$dev_value" = "$template_value" ] || fail "$key doit rester cohérent entre .env.template et .env.dev"
  [ "$prod_value" = "$template_value" ] || fail "$key doit rester cohérent entre .env.template et .env.prod"
}

[ -f "INVARIANTS.md" ] || fail "INVARIANTS.md est manquant"
[ -f ".env.template" ] || fail ".env.template est manquant"
[ -f ".env.dev" ] || fail ".env.dev est manquant"
[ -f ".env.prod" ] || fail ".env.prod est manquant"
[ -f ".env.local" ] || fail ".env.local est manquant"
[ -L ".env" ] || fail ".env doit être un lien symbolique vers .env.dev ou .env.prod"

TARGET="$(readlink .env)"

if [ "$TARGET" != ".env.dev" ] && [ "$TARGET" != ".env.prod" ]; then
  fail ".env doit pointer vers .env.dev ou .env.prod"
fi

assert_same_value APP_NAME
assert_same_value APP_SLUG
assert_same_value APP_DEPOT
assert_same_value APP_NO

set -a
source .env
set +a

[ -n "${APP_NAME:-}" ] || fail "APP_NAME est manquant"
[ -n "${APP_SLUG:-}" ] || fail "APP_SLUG est manquant"
[ -n "${APP_DEPOT:-}" ] || fail "APP_DEPOT est manquant"
[ -n "${APP_NO:-}" ] || fail "APP_NO est manquant"
[ -n "${APP_ENV:-}" ] || fail "APP_ENV est manquant"

[ "$APP_ENV" = "dev" ] || [ "$APP_ENV" = "prod" ] || fail "APP_ENV doit être dev ou prod"

if [ "$TARGET" = ".env.dev" ] && [ "$APP_ENV" != "dev" ]; then
  fail ".env pointe vers .env.dev mais APP_ENV n'est pas dev"
fi

if [ "$TARGET" = ".env.prod" ] && [ "$APP_ENV" != "prod" ]; then
  fail ".env pointe vers .env.prod mais APP_ENV n'est pas prod"
fi

EXPECTED_DB_PORT=$((5432 + APP_NO))
EXPECTED_VITE_PORT=$((5173 + APP_NO))
EXPECTED_API_PORT=$((8000 + APP_NO + 1))

if [ "$(read_env_value .env.dev DEV_DB_PORT)" != "$EXPECTED_DB_PORT" ]; then
  fail "DEV_DB_PORT devrait être $EXPECTED_DB_PORT"
fi
if [ "$(read_env_value .env.dev DEV_VITE_PORT)" != "$EXPECTED_VITE_PORT" ]; then
  fail "DEV_VITE_PORT devrait être $EXPECTED_VITE_PORT"
fi
if [ "$(read_env_value .env.dev DEV_API_PORT)" != "$EXPECTED_API_PORT" ]; then
  fail "DEV_API_PORT devrait être $EXPECTED_API_PORT"
fi

[ "$(read_env_value .env.dev POSTGRES_USER)" = "${APP_SLUG}_pg_user" ] || fail "POSTGRES_USER devrait être ${APP_SLUG}_pg_user"
[ "$(read_env_value .env.prod POSTGRES_USER)" = "${APP_SLUG}_pg_user" ] || fail "POSTGRES_USER devrait être ${APP_SLUG}_pg_user"
[ "$(read_env_value .env.dev POSTGRES_DB)" = "${APP_SLUG}_pg_db" ] || fail "POSTGRES_DB devrait être ${APP_SLUG}_pg_db"
[ "$(read_env_value .env.prod POSTGRES_DB)" = "${APP_SLUG}_pg_db" ] || fail "POSTGRES_DB devrait être ${APP_SLUG}_pg_db"

[ -f "docker-compose.${APP_ENV}.yml" ] || fail "docker-compose.${APP_ENV}.yml est manquant"

if grep -q "^\.env$" .gitignore 2>/dev/null; then
  true
else
  fail ".gitignore doit ignorer .env"
fi

if grep -q "^\.env.local$" .gitignore 2>/dev/null; then
  true
else
  fail ".gitignore doit ignorer .env.local"
fi

if grep -q "^\.env.template$" .gitignore 2>/dev/null; then
  true
else
  fail ".gitignore doit ignorer .env.template"
fi

if [ "$EXPECT_APPLICATION" -eq 1 ]; then
  ./scripts/materialize-application.py validate --expect-application
else
  ./scripts/materialize-application.py validate
fi

echo "OK: invariants valides pour APP_ENV=$APP_ENV"
