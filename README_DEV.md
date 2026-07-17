# **APP_NAME** — README_DEV

Application basée sur les invariants standards du template applicatif.

Ce fichier décrit le démarrage local, la matérialisation d’une copie du template et les commandes développeur.

---

## Démarrage rapide

Depuis une copie du dépôt :

```bash
cp .env.template.example .env.template
make dev
make init
```

Le `Makefile` est la méthode recommandée pour les commandes courantes. Il délègue aux scripts standards du projet, qui restent la source de vérité.

`make init` appelle :

```bash
./scripts/init.sh
```

Ce script lit `.env.template`, respecte le lien `.env` déjà en place, génère ou complète les fichiers d’environnement, valide les invariants et ne démarre les services que si nécessaire.

---

## Matérialiser une application

Le dépôt source du template conserve `.app-template/template.json`.

Quand une copie doit devenir une application indépendante, la matérialisation doit être explicitement demandée :

```bash
APP_TEMPLATE_MATERIALIZE=1 make init
```

Effets :

* validation de l’identité dans `.env.template` ;
* remplacement de `__APP_NAME__` et `__APP_SLUG__` ;
* écriture de `.app-template/origin.json` ;
* suppression de la métadonnée de template active ;
* vérification finale de l’état applicatif.

Pour réinitialiser explicitement l’historique Git après matérialisation :

```bash
APP_TEMPLATE_MATERIALIZE=1 APP_TEMPLATE_DETACH_GIT=1 make init
```

Protections :

* la matérialisation du dépôt source `app-template` est refusée par défaut ;
* le détachement Git n’a lieu que si `APP_TEMPLATE_DETACH_GIT=1` ;
* un état ambigu entre template et application est refusé ;
* les placeholders restants bloquent la validation.

Variables de compatibilité héritée :

* `DOCFORGE_INIT_APPLICATION`
* `DOCFORGE_DETACH_GIT`
* `DOCFORGE_ALLOW_SOURCE_NAME`
* `DOCFORGE_SKIP_STARTUP`

Ces variables sont encore acceptées temporairement, mais les variables `APP_TEMPLATE_*` sont prioritaires et le flux normal ne doit plus les documenter comme premier choix.

---

## Commandes courantes

### Aide

```bash
make help
```

### Démarrer les services

```bash
make up
```

### Voir l’état des services

```bash
make ps
```

### Voir les logs

```bash
make logs
```

Ou pour un service précis :

```bash
make logs SERVICE=backend
make logs SERVICE=frontend
make logs SERVICE=db
```

### Redémarrer

```bash
make restart
```

### Reconstruire les images

```bash
make rebuild
```

Ou pour un service précis :

```bash
make rebuild SERVICE=backend
make rebuild SERVICE=frontend
```

Important :

* `make rebuild` reconstruit les images mais ne redémarre pas à lui seul les conteneurs ;
* après un rebuild, utiliser `make up` pour relancer les services avec les nouvelles images ;
* si le backend change, exécuter ensuite `make migrate`.

### Appliquer les migrations

```bash
make migrate
```

Cette cible exécute `python manage.py migrate` dans le service `backend` de l’environnement actif.

### Validation structurelle

```bash
make check
```

`make check` valide les invariants structurels du modèle, notamment :

* cohérence de `APP_NAME`, `APP_SLUG`, `APP_DEPOT` et `APP_NO` ;
* ports dérivés de `APP_NO` ;
* conventions PostgreSQL ;
* validité du lien `.env` ;
* état des métadonnées `.app-template/*` ;
* absence de placeholders restants lorsque le dépôt est matérialisé.

### Backup PostgreSQL

```bash
make backup
```

### Restaurer un backup PostgreSQL

```bash
make restore
make restore FILE=./backup/__APP_SLUG___db-YYYYMMDD_HHMMSS.sql.gz
```

Comportement :

* le backup le plus récent est utilisé si `FILE` n’est pas fourni ;
* une confirmation interactive est demandée ;
* le schéma `public` est recréé avant import ;
* la restauration remplace les données actuelles de la base active ;
* la commande s’arrête au premier incident PostgreSQL.

### Mise à jour standard de l’application

```bash
make update
```

Séquence exécutée :

1. `make backup`
2. `git pull --ff-only`
3. `make check`
4. `make rebuild`
5. `make up`
6. `make migrate`
7. `make ps`

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

Le fichier `.env.local` ne doit jamais être commité.

---

## Changer d’environnement

### Développement

```bash
make dev
```

### Production

```bash
make prod
```

Le lien symbolique `.env` détermine l’environnement actif utilisé par :

```bash
make up
make rebuild
make migrate
make backup
make restore
make update
```

---

## Génération des environnements

Normalement, cette étape est faite automatiquement par :

```bash
make init
```

En cas de besoin :

```bash
cp .env.template.example .env.template
```

Puis remplir les variables du projet dans `.env.template` :

```bash
APP_NAME=
APP_SLUG=
APP_DEPOT=
APP_NO=
ADMIN_USERNAME=
ADMIN_PASSWORD=
ADMIN_EMAIL=
```

Puis choisir l’environnement actif :

```bash
make dev
# ou
make prod
```

Ensuite :

```bash
./scripts/generate-env.sh
./scripts/generate-secrets.sh
```

`./scripts/generate-env.sh` lit l’identité du projet et les variables `ADMIN_*` de bootstrap depuis `.env.template`, puis régénère `.env.dev` et `.env.prod` et y recalcule notamment :

* `POSTGRES_USER` et `POSTGRES_DB` à partir de `APP_SLUG` ;
* `DEV_DB_PORT`, `DEV_VITE_PORT` et `DEV_API_PORT` à partir de `APP_NO` ;
* `DJANGO_ALLOWED_HOSTS` et `DJANGO_CSRF_TRUSTED_ORIGINS` pour les environnements dev et prod ;
* `VITE_API_BASE` ainsi que les variables de stack non secrètes du template.

Le script crée aussi `.env.local` si nécessaire et ajoute sans écraser les clés manquantes suivantes :

* `ADMIN_USERNAME`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`
* `POSTGRES_PASSWORD`, `DJANGO_SECRET_KEY`
* `<APP_DEPOT_NORMALISE>_API_TOKEN`

Les secrets sont générés par :

```bash
./scripts/generate-secrets.sh
```

---

## Démarrage manuel équivalent

À titre informatif seulement, `./scripts/init.sh` remplace normalement cette séquence :

```bash
./scripts/generate-env.sh
./scripts/check-invariants.sh
./scripts/up.sh
./scripts/ps.sh
```

Avec matérialisation explicite :

```bash
APP_TEMPLATE_MATERIALIZE=1 ./scripts/init.sh
```

Une mise à jour manuelle équivalente à `make update` correspond à :

```bash
./scripts/backup-db.sh
git pull --ff-only
./scripts/check-invariants.sh
./scripts/rebuild.sh
./scripts/up.sh
./scripts/migrate.sh
./scripts/ps.sh
```

---

## Intégration facultative avec DocForge

DocForge peut analyser une application après sa matérialisation et lire `.app-template/origin.json` pour identifier le modèle d’origine.

DocForge n’est pas requis pour :

* `make init` ;
* `make up` ;
* `make migrate` ;
* `make check` ;
* la matérialisation du template.
