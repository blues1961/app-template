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
make init
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
./scripts/migrate.sh
./scripts/backup-db.sh
./scripts/restore-db.sh
./scripts/update.sh
```

Le `Makefile` expose les cibles usuelles correspondantes :

```bash
make init
make up
make down
make restart
make rebuild
make logs
make ps
make check
make migrate
make backup
make restore
make update
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

Rôle des fichiers :

```text
.env.dev      Variables non secrètes pour le développement
.env.prod     Variables non secrètes pour la production
.env.local    Secrets locaux non versionnés
.env          Lien symbolique vers .env.dev ou .env.prod
```

En usage normal :

```bash
make dev
make prod
```

Le template s’appuie sur l’environnement actif pointé par `.env` pour les commandes de maintenance comme `make migrate`, `make backup`, `make restore` et `make update`.

---

## Procédures standard

Mise à jour des services :

```bash
make rebuild
make up
make migrate
make ps
```

Backup PostgreSQL :

```bash
make backup
```

Restauration PostgreSQL :

```bash
make restore
make restore FILE=./backup/__APP_SLUG___db-YYYYMMDD_HHMMSS.sql.gz
```

Attention :

* `make restore` remplace les données actuelles de la base active ;
* le script réinitialise le schéma `public` avant import ;
* la restauration échoue au premier problème PostgreSQL ;
* il est recommandé de faire un `make backup` avant toute restauration.

Mise à jour applicative standard :

```bash
make update
```

La cible `update` exécute :

1. `make backup`
2. `git pull --ff-only`
3. `make check`
4. `make rebuild`
5. `make up`
6. `make migrate`
7. `make ps`

Cette procédure fonctionne en développement et en production tant que `.env` pointe vers le bon environnement et que le dépôt Git local est dans un état compatible avec `git pull --ff-only`.

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
