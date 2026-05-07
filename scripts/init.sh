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
[ -f ".env.template" ] || err ".env.template introuvable"

# -----------------------------
# Chargement du template (source de vérité)
# -----------------------------
log "Chargement de .env.template"
set -a
source .env.template
set +a

# Validation minimale
[ -n "${APP_NAME:-}" ] || err "APP_NAME non défini dans .env.template"
[ -n "${APP_SLUG:-}" ] || err "APP_SLUG non défini dans .env.template"

ok "Template chargé (${APP_NAME})"

# -----------------------------
# Génération des fichiers env
# -----------------------------
log "Génération des fichiers d'environnement"
./scripts/generate-env.sh
ok ".env générés"

# -----------------------------
# Création du lien symbolique (.env -> .env.dev)
# -----------------------------
log "Configuration de l'environnement actif (dev)"

ln -sf .env.dev .env
ok ".env → .env.dev"

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
