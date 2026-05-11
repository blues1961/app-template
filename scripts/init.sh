#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Utils
# -----------------------------
log()  { echo -e "\033[1;34m→ $1\033[0m"; }
ok()   { echo -e "\033[1;32m✔ $1\033[0m"; }
warn() { echo -e "\033[1;33m⚠ $1\033[0m"; }
err()  { echo -e "\033[1;31m✖ $1\033[0m"; exit 1; }

# -----------------------------
# Vérifications de base
# -----------------------------
[ -f ".env.template" ] || err ".env.template introuvable. Copie d'abord .env.template.example vers .env.template"

TARGET_ENV="${1:-dev}"

if [ "$TARGET_ENV" != "dev" ] && [ "$TARGET_ENV" != "prod" ]; then
  err "Usage: ./scripts/init.sh [dev|prod]"
fi

# -----------------------------
# Chargement du template (source de vérité)
# -----------------------------
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

log "Chargement de .env.template"
load_template .env.template

# Validation minimale
[ -n "${APP_NAME:-}" ] || err "APP_NAME non défini dans .env.template"
[ -n "${APP_SLUG:-}" ] || err "APP_SLUG non défini dans .env.template"
[ -n "${APP_DEPOT:-}" ] || err "APP_DEPOT non défini dans .env.template"
[ -n "${APP_NO:-}" ] || err "APP_NO non défini dans .env.template"

ok "Template chargé (${APP_NAME})"

# -----------------------------
# Génération des fichiers env
# -----------------------------
log "Génération des fichiers d'environnement"
./scripts/generate-env.sh
ok ".env générés"

# -----------------------------
# Création du lien symbolique (.env -> .env.dev|.env.prod)
# -----------------------------
log "Configuration de l'environnement actif (${TARGET_ENV})"
./scripts/env-switch.sh "$TARGET_ENV"
ok ".env → .env.${TARGET_ENV}"

# -----------------------------
# Fonction templating sécurisée
# -----------------------------
replace_placeholder() {
  local file="$1"
  local placeholder="$2"
  local value="$3"

  [ -f "$file" ] || { warn "$file introuvable"; return; }

  # Escape caractères spéciaux pour sed
  local safe_value
  safe_value=$(printf '%s\n' "$value" | sed 's/[&/\]/\\&/g')

  sed -i "s/${placeholder}/${safe_value}/g" "$file"
  ok "$file mis à jour (${placeholder})"
}

# -----------------------------
# Injection des variables de template
# -----------------------------
log "Mise à jour des fichiers templatisés"

replace_placeholder README.md "\*\*APP_NAME\*\*" "$APP_NAME"
replace_placeholder README_DEV.md "\*\*APP_NAME\*\*" "$APP_NAME"
replace_placeholder README.md "__APP_NAME__" "$APP_NAME"
replace_placeholder README_DEV.md "__APP_NAME__" "$APP_NAME"
replace_placeholder Makefile "__APP_SLUG__" "$APP_SLUG"
replace_placeholder backend/api/views.py "__APP_NAME__" "$APP_NAME"
replace_placeholder frontend/index.html "__APP_NAME__" "$APP_NAME"
replace_placeholder frontend/src/App.jsx "__APP_NAME__" "$APP_NAME"

# Optionnel (fortement recommandé)
replace_placeholder README.md "__APP_SLUG__" "$APP_SLUG"
replace_placeholder README_DEV.md "__APP_SLUG__" "$APP_SLUG"
echo "→ Remplacement des placeholders dans les scripts"

find scripts -type f -name "*.sh" -exec sed -i "s/__APP_SLUG__/${APP_SLUG}/g" {} \;

echo "✔ Placeholders remplacés"

# -----------------------------
# Vérification des invariants
# -----------------------------
log "Vérification des invariants"
if [ -f "./scripts/check-invariants.sh" ]; then
  ./scripts/check-invariants.sh || warn "Invariants non respectés"
else
  warn "check-invariants.sh non trouvé"
fi

# -----------------------------
# Démarrage des conteneurs
# -----------------------------
log "Démarrage des conteneurs"
./scripts/up.sh

# -----------------------------
# Statut des conteneurs
# -----------------------------
log "Statut des conteneurs"
./scripts/ps.sh

ok "Initialisation terminée 🚀"
