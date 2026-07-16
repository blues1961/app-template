#!/usr/bin/env bash
set -euo pipefail

log()  { echo -e "\033[1;34m→ $1\033[0m"; }
ok()   { echo -e "\033[1;32m✔ $1\033[0m"; }
warn() { echo -e "\033[1;33m⚠ $1\033[0m"; }
err()  { echo -e "\033[1;31m✖ $1\033[0m"; exit 1; }

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

if [ -f "docforge.template.json" ] && [ ! -f "docforge.project.json" ]; then
  TEMPLATE_ID=$(python3 - <<'PYTHON'
import json
from pathlib import Path
payload = json.loads(Path('docforge.template.json').read_text(encoding='utf-8'))
print(payload.get('template_id', 'app-template'))
PYTHON
)
  if [ "$(basename "$PWD")" != "$TEMPLATE_ID" ] && [ "${DOCFORGE_INIT_APPLICATION:-0}" != "1" ]; then
    err "Ce dépôt ressemble à une nouvelle application issue du template. Relance avec DOCFORGE_INIT_APPLICATION=1 make init pour matérialiser docforge.project.json avant le démarrage."
  fi
  if [ "${DOCFORGE_INIT_APPLICATION:-0}" = "1" ]; then
    log "Matérialisation des métadonnées DocForge de l'application"
    DOCFORGE_METADATA_ARGS=(materialize-application)
    if [ "${DOCFORGE_DETACH_GIT:-0}" = "1" ]; then
      DOCFORGE_METADATA_ARGS+=(--detach-git)
    fi
    if [ "${DOCFORGE_ALLOW_SOURCE_NAME:-0}" = "1" ]; then
      DOCFORGE_METADATA_ARGS+=(--allow-source-name)
    fi
    ./scripts/docforge-project-metadata.py "${DOCFORGE_METADATA_ARGS[@]}"
    ok "Métadonnées DocForge d'application matérialisées"
  else
    warn "Mode template source conservé: docforge.template.json reste actif."
  fi
fi

log "Génération des fichiers d'environnement"
./scripts/generate-env.sh
ok ".env.dev, .env.prod et .env.local prêts"

log "Vérification des invariants"
CHECK_ARGS=()
if [ "${DOCFORGE_INIT_APPLICATION:-0}" = "1" ]; then
  CHECK_ARGS+=(--expect-application)
fi
./scripts/check-invariants.sh "${CHECK_ARGS[@]}"
ok "Invariants validés"

set -a
source .env
set +a

COMPOSE_FILE="docker-compose.${APP_ENV}.yml"
[ -f "$COMPOSE_FILE" ] || err "$COMPOSE_FILE introuvable"

if [ "${DOCFORGE_SKIP_STARTUP:-0}" = "1" ]; then
  warn "DOCFORGE_SKIP_STARTUP=1: démarrage et vérification Docker Compose ignorés après la validation."
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
