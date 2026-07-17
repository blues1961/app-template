#!/usr/bin/env bash
set -euo pipefail

log()  { echo -e "\033[1;34m→ $1\033[0m" >&2; }
ok()   { echo -e "\033[1;32m✔ $1\033[0m" >&2; }
warn() { echo -e "\033[1;33m⚠ $1\033[0m" >&2; }
err()  { echo -e "\033[1;31m✖ $1\033[0m" >&2; exit 1; }

resolve_compat_flag() {
  local new_name="$1"
  local old_name="$2"
  local default_value="$3"
  local new_is_set=0
  local old_is_set=0
  local value="$default_value"

  if [ "${!new_name+x}" = "x" ]; then
    new_is_set=1
    value="${!new_name}"
  fi

  if [ "${!old_name+x}" = "x" ]; then
    old_is_set=1
  fi

  if [ "$new_is_set" -eq 0 ] && [ "$old_is_set" -eq 1 ]; then
    warn "${old_name} est dépréciée; utilisez ${new_name}."
    value="${!old_name}"
  elif [ "$new_is_set" -eq 1 ] && [ "$old_is_set" -eq 1 ] && [ "${!old_name}" != "$value" ]; then
    warn "${old_name} est ignorée car ${new_name} est prioritaire."
  fi

  printf '%s' "$value"
}

read_template_id() {
  python3 - <<'PYTHON'
import json
from pathlib import Path

for candidate in (Path('.app-template/template.json'), Path('docforge.template.json')):
    if candidate.is_file():
        payload = json.loads(candidate.read_text(encoding='utf-8'))
        print(payload.get('template_id', 'app-template'))
        break
else:
    print('app-template')
PYTHON
}

APP_TEMPLATE_MATERIALIZE_FLAG="$(resolve_compat_flag APP_TEMPLATE_MATERIALIZE DOCFORGE_INIT_APPLICATION 0)"
APP_TEMPLATE_DETACH_GIT_FLAG="$(resolve_compat_flag APP_TEMPLATE_DETACH_GIT DOCFORGE_DETACH_GIT 0)"
APP_TEMPLATE_ALLOW_SOURCE_NAME_FLAG="$(resolve_compat_flag APP_TEMPLATE_ALLOW_SOURCE_NAME DOCFORGE_ALLOW_SOURCE_NAME 0)"
APP_TEMPLATE_SKIP_STARTUP_FLAG="$(resolve_compat_flag APP_TEMPLATE_SKIP_STARTUP DOCFORGE_SKIP_STARTUP 0)"

[ -f ".env.template" ] || err ".env.template introuvable. Copie d'abord .env.template.example vers .env.template"
[ -L ".env" ] || err ".env doit être un lien symbolique vers .env.dev ou .env.prod. Utilise make dev ou make prod avant make init"

ENV_LINK_TARGET="$(readlink .env)"
case "$ENV_LINK_TARGET" in
  .env.dev)
    TARGET_ENV="dev"
    ;;
  .env.prod)
    TARGET_ENV="prod"
    ;;
  *)
    err ".env doit pointer vers .env.dev ou .env.prod"
    ;;
esac

log "Initialisation pour l'environnement actif (${TARGET_ENV})"

if [ -f ".app-template/template.json" ] || [ -f "docforge.template.json" ]; then
  TEMPLATE_ID="$(read_template_id)"
  if [ "$(basename "$PWD")" != "$TEMPLATE_ID" ] && [ "$APP_TEMPLATE_MATERIALIZE_FLAG" != "1" ]; then
    err "Ce dépôt ressemble à une nouvelle application issue du template. Relance avec APP_TEMPLATE_MATERIALIZE=1 make init pour matérialiser .app-template/origin.json avant le démarrage."
  fi
  if [ "$APP_TEMPLATE_MATERIALIZE_FLAG" = "1" ]; then
    log "Matérialisation app-template de l'application"
    METADATA_ARGS=(materialize-application)
    if [ "$APP_TEMPLATE_DETACH_GIT_FLAG" = "1" ]; then
      METADATA_ARGS+=(--detach-git)
    fi
    if [ "$APP_TEMPLATE_ALLOW_SOURCE_NAME_FLAG" = "1" ]; then
      METADATA_ARGS+=(--allow-source-name)
    fi
    ./scripts/materialize-application.py "${METADATA_ARGS[@]}"
    ok "Métadonnées d'application matérialisées"
  else
    warn "Mode template source conservé: .app-template/template.json reste actif."
  fi
fi

log "Génération des fichiers d'environnement"
./scripts/generate-env.sh
ok ".env.dev, .env.prod et .env.local prêts"

log "Vérification des invariants"
CHECK_ARGS=()
if [ "$APP_TEMPLATE_MATERIALIZE_FLAG" = "1" ]; then
  CHECK_ARGS+=(--expect-application)
fi
./scripts/check-invariants.sh "${CHECK_ARGS[@]}"
ok "Invariants validés"

set -a
source .env
set +a

COMPOSE_FILE="docker-compose.${APP_ENV}.yml"
[ -f "$COMPOSE_FILE" ] || err "$COMPOSE_FILE introuvable"

if [ "$APP_TEMPLATE_SKIP_STARTUP_FLAG" = "1" ]; then
  warn "APP_TEMPLATE_SKIP_STARTUP=1: démarrage et vérification Docker Compose ignorés après la validation."
else
  EXPECTED_SERVICES=$(docker compose \
    --env-file .env \
    --env-file .env.local \
    -f "$COMPOSE_FILE" \
    config --services | sed '/^$/d')

  RUNNING_SERVICES=$(docker compose \
    --env-file .env \
    --env-file .env.local \
    -f "$COMPOSE_FILE" \
    ps --services --filter status=running 2>/dev/null | sed '/^$/d' || true)

  services_missing=0
  while IFS= read -r service; do
    [ -n "$service" ] || continue
    if ! printf '%s\n' "$RUNNING_SERVICES" | grep -Fxq "$service"; then
      services_missing=1
      break
    fi
  done <<< "$EXPECTED_SERVICES"

  if [ "$services_missing" -eq 1 ]; then
    log "Démarrage des services manquants ou arrêtés"
    ./scripts/up.sh
  else
    ok "Services déjà actifs, aucun redémarrage forcé"
  fi

  log "Statut des conteneurs"
  ./scripts/ps.sh
fi

ok "Initialisation terminée"
