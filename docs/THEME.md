# Thème commun des applications auto-hébergées

Le frontend du template inclut un thème clair/sombre commun aux applications `mon-site.ca`.

## Fichiers

- `frontend/src/theme.css` contient les variables visuelles partagées.
- `frontend/src/styles.css` contient le layout de base, le login, les boutons et les surfaces.
- `frontend/src/components/ThemeToggle.jsx` gère le choix clair/sombre.
- `frontend/src/components/LoginForm.jsx` fournit la structure de login standard.
- `frontend/src/assets/` contient les assets communs `mon-site-logo.png`, `mon-site-symbol.png` et `meteo-bg.jpg`.

## Règles

- Le choix de thème est appliqué via `data-theme="light|dark"` sur `document.documentElement`.
- La préférence utilisateur est persistée dans `localStorage` avec la clé `mon-site.theme`.
- Le login standard place le logo et le sélecteur de thème dans le même en-tête.
- Le nom de l’application utilise la classe `eyebrow` et la variable `--accent-strong`.
- En thème clair, les textes de boutons utilisent un bleu foncé plutôt que du blanc.
- Les appels API frontend doivent rester relatifs à `/api`.

## Adaptation

Les futures applications peuvent remplacer le contenu de démonstration de `App.jsx`, mais doivent conserver les tokens de thème, les assets communs et la structure de login sauf besoin explicite du domaine.
