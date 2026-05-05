# **APP_NAME**

Application générée à partir du template applicatif standard.

Ce projet respecte les invariants définis dans `INVARIANTS.md` et utilise une structure commune pour faciliter le développement, le déploiement et la maintenance.

---

## Objectif

Ce projet sert de base pour une application auto-hébergée avec :

* frontend ;
* backend ;
* base de données PostgreSQL lorsque nécessaire ;
* environnements séparés développement / production ;
* scripts standards de gestion ;
* configuration compatible Docker Compose ;
* déploiement prévu derrière Traefik.

---

## Structure générale

```text
.
├── backend/
├── frontend/
├── docs/
├── scripts/
├── docker-compose.dev.yml
├── docker-compose.prod.yml
├── INVARIANTS.md
├── README.md
├── README_DEV.md
├── AGENTS.md
└── CODEX_START.md
```

---

## Démarrage rapide

Pour démarrer en développement :

```bash
./scripts/init.sh
```

Voir les détails dans :

```text
README_DEV.md
```

---

## Scripts standards

Les opérations courantes passent par les scripts du dossier `scripts/` :

```bash
./scripts/init.sh
./scripts/up.sh
./scripts/down.sh
./scripts/restart.sh
./scripts/rebuild.sh
./scripts/logs.sh
./scripts/ps.sh
./scripts/check-invariants.sh
```

---

## Environnements

Le projet utilise :

```text
.env.dev
.env.prod
.env.local
.env
```

`.env.local` contient les secrets et ne doit jamais être commité.

---

## Documentation

* `README_DEV.md` : démarrage local et commandes développeur
* `INVARIANTS.md` : conventions obligatoires du projet
* `AGENTS.md` : instructions générales pour les agents IA
* `CODEX_START.md` : point de départ pour Codex
* `docs/` : documentation complémentaire

---

## Règle principale

Ne pas lancer Docker Compose directement dans l’usage courant.

Utiliser les scripts standards du projet.
