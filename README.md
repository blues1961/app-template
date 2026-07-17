# **APP_NAME**

Application générée à partir du template applicatif standard.

Ce dépôt reste autonome : `app-template` gère lui-même la matérialisation, l’identité du projet, les métadonnées de provenance, les protections Git et la validation structurelle. Un outil externe comme DocForge peut lire ces métadonnées après coup, mais il n’est pas requis pour créer, démarrer ou vérifier l’application.

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
├── .app-template/
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

`.app-template/` contient les métadonnées permanentes du modèle :

```text
.app-template/template.json   Dépôt source du template
.app-template/origin.json     Application matérialisée
```

Le dépôt ne doit jamais contenir les deux à la fois.

---

## Démarrage rapide

Dans une copie du template :

```bash
cp .env.template.example .env.template
make dev
make init
```

Si la copie est destinée à devenir une application indépendante, utiliser le flux de matérialisation :

```bash
APP_TEMPLATE_MATERIALIZE=1 make init
```

Pour détacher explicitement l’historique Git après matérialisation :

```bash
APP_TEMPLATE_MATERIALIZE=1 APP_TEMPLATE_DETACH_GIT=1 make init
```

Voir les détails dans `README_DEV.md`.

---

## Scripts standards

Les opérations courantes passent par les scripts du dossier `scripts/` :

```bash
./scripts/init.sh
./scripts/generate-env.sh
./scripts/generate-secrets.sh
./scripts/materialize-application.py
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
.env.template
.env.dev
.env.prod
.env.local
.env
```

Rôle des fichiers :

```text
.env.template  Identité locale du projet avant génération
.env.dev       Variables non secrètes pour le développement
.env.prod      Variables non secrètes pour la production
.env.local     Secrets locaux non versionnés
.env           Lien symbolique vers .env.dev ou .env.prod
```

Le template s’appuie sur l’environnement actif pointé par `.env` pour les commandes de maintenance comme `make migrate`, `make backup`, `make restore` et `make update`.

---

## Métadonnées du template

Le cycle de vie appartient à `app-template`.

* `.app-template/template.json` décrit le dépôt source du modèle.
* `.app-template/origin.json` conserve la provenance du modèle après matérialisation.
* la matérialisation remplace les placeholders `__APP_NAME__` et `__APP_SLUG__`.
* les protections empêchent la coexistence d’un état template et d’un état application.

Compatibilité héritée :

* `DOCFORGE_INIT_APPLICATION` et `DOCFORGE_DETACH_GIT` restent temporairement acceptées avec avertissement ;
* `docforge.template.json` et `docforge.project.json` sont encore lus à titre de compatibilité, mais le format canonique est désormais `.app-template/*`.

---

## Procédures standard

Mise à jour des services :

```bash
make rebuild
make up
make migrate
make ps
```

Validation structurelle :

```bash
make check
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

---

## Documentation

* `README_DEV.md` : démarrage local, matérialisation et commandes développeur
* `INVARIANTS.md` : conventions obligatoires du projet
* `AGENTS.md` : instructions générales pour les agents IA
* `CODEX_START.md` : point de départ pour Codex
* `docs/` : documentation complémentaire

---

## Intégration facultative avec DocForge

DocForge peut analyser une application après sa matérialisation et lire les métadonnées génériques produites par `app-template`.

DocForge n’est pas requis pour :

* créer l’application ;
* générer les environnements ;
* détacher Git ;
* démarrer les services ;
* lancer `make check`.

---

## Règle principale

Ne pas lancer Docker Compose directement dans l’usage courant.

Utiliser les scripts standards du projet.
