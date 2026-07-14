# AGENTS.md

## Rôle de l’agent Codex

Tu es chargé d’aider au développement d’une application auto-hébergée basée sur ce template.

Ton objectif est de produire du code propre, cohérent, maintenable et conforme aux conventions du projet.
Avant de modifier le code, tu dois lire les fichiers de référence du dépôt, en particulier :

* `README.md`
* `README_DEV.md`
* `INVARIANTS.md`
* `CODEX_START.md`
* `specification.md` si le fichier existe
* `.env.template`
* `docker-compose.dev.yml`
* `docker-compose.prod.yml`

Tu dois respecter la structure existante du projet et éviter les décisions implicites qui modifieraient les conventions établies.

---

## Priorité des documents

En cas de contradiction entre plusieurs fichiers, applique l’ordre de priorité suivant :

1. `specification.md`
2. `INVARIANTS.md`
3. `.env.template`
4. `README_DEV.md`
5. `README.md`
6. `CODEX_START.md`
7. Le code existant

Si une information est absente ou ambiguë, ne modifie pas les conventions globales sans justification explicite.

---

## Conventions générales du projet

Ce dépôt est un template pour des applications auto-hébergées.

Les applications suivent généralement cette structure :

```text
.
├── backend/
├── frontend/
├── docs/
├── scripts/
├── docker-compose.dev.yml
├── docker-compose.prod.yml
├── .env.template
├── README.md
├── README_DEV.md
├── INVARIANTS.md
├── CODEX_START.md
└── specification.md
```

Les services standards sont :

* `db`
* `backend`
* `frontend`

Les noms de conteneurs doivent suivre la convention :

```text
${APP_SLUG}_db_${APP_ENV}
${APP_SLUG}_backend_${APP_ENV}
${APP_SLUG}_frontend_${APP_ENV}
```

Exemple :

```text
con_db_dev
con_backend_dev
con_frontend_dev
```

---

## Gestion des environnements

Le projet utilise les fichiers suivants :

```text
.env.template
.env.dev
.env.prod
.env.local
.env
```

Règles importantes :

* `.env.template` définit l’identité initiale du projet.
* `.env.dev` contient la configuration de développement.
* `.env.prod` contient la configuration de production.
* `.env.local` contient les secrets et ne doit jamais être commité.
* `.env` est un lien symbolique vers `.env.dev` ou `.env.prod`.

Le lien symbolique `.env` doit exister avant le démarrage normal de l’application.

En développement :

```bash
.env -> .env.dev
```

En production :

```bash
.env -> .env.prod
```

---

## Secrets

Les secrets ne doivent jamais être écrits dans les fichiers suivis par Git.

Les variables sensibles doivent être placées uniquement dans :

```text
.env.local
```

Exemples de variables sensibles :

```text
POSTGRES_PASSWORD
JWT_SECRET
DJANGO_SECRET_KEY
ADMIN_USERNAME
ADMIN_EMAIL
ADMIN_PASSWORD
```

Ne jamais afficher, commiter ou documenter de vraies valeurs de secrets.

Les fichiers suivants doivent rester ignorés par Git :

```text
.env.local
.env
*.bak
cookies.txt
dev.cookies
prod.cookies
backups/
```

---

## Variables d’identité du projet

Le fichier `.env.template` sert à définir l’identité de l’application.

Les variables importantes sont :

```env
APP_NAME=
APP_SLUG=
APP_DEPOT=
APP_ENV=
APP_NO=
APP_HOST=
```

Règles :

* `APP_NAME` est le nom lisible de l’application.
* `APP_SLUG` est l’identifiant court utilisé pour les services, conteneurs et variables.
* `APP_DEPOT` est le nom du dépôt Git.
* `APP_ENV` vaut `dev` ou `prod`.
* `APP_NO` sert à dériver les ports de développement.
* `APP_HOST` correspond au domaine public en production.

Par défaut, le domaine public suggéré est :

```text
${APP_SLUG}.mon-site.ca
```

---

## Ports de développement

Les ports de développement sont dérivés de `APP_NO`.

Pour `APP_NO=N` :

```text
DEV_DB_PORT=5432 + N
DEV_VITE_PORT=5173 + N
DEV_API_PORT=8000 + N + 1
```

Exemple avec `APP_NO=4` :

```text
DEV_DB_PORT=5436
DEV_VITE_PORT=5177
DEV_API_PORT=8005
```

Ne change jamais `APP_NO` sans demande explicite.

Ne remplace pas les ports dérivés par des valeurs codées en dur si le projet utilise déjà les variables d’environnement.

---

## Commandes Docker Compose

Utiliser la syntaxe moderne :

```bash
docker compose
```

Ne pas utiliser :

```bash
docker-compose
```

Les commandes doivent inclure explicitement le fichier d’environnement et le fichier compose.

Développement :

```bash
docker compose --env-file .env.dev -f docker-compose.dev.yml up -d --build
```

Production :

```bash
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
```

Si `.env.local` est utilisé par les services, il doit être référencé dans les fichiers Compose avec `env_file`.

Exemple :

```yaml
env_file:
  - .env
  - .env.local
```

---

## Scripts

Le dossier `scripts/` contient les commandes d’exploitation du projet.

Les scripts standards peuvent inclure :

```text
scripts/init.sh
scripts/env-switch.sh
scripts/up.sh
scripts/down.sh
scripts/restart.sh
scripts/logs.sh
scripts/ps.sh
scripts/check-invariants.sh
```

Les scripts doivent :

* être compatibles Ubuntu/Linux ;
* utiliser Bash ;
* utiliser `docker compose` ;
* respecter `APP_ENV` ;
* charger les bons fichiers `.env.*` ;
* éviter les valeurs codées en dur ;
* échouer clairement en cas d’erreur.

Les scripts doivent pouvoir être exécutés depuis la racine du projet.

---

## Initialisation du projet

Le script d’initialisation doit normalement :

1. Lire `.env.template`.
2. Générer `.env.dev`.
3. Générer `.env.prod`.
4. Générer ou préserver `.env.local`.
5. Créer le lien symbolique `.env -> .env.dev`.
6. Remplacer les marqueurs de template dans les fichiers de documentation.
7. Démarrer les conteneurs de développement.
8. Afficher l’état des services avec `scripts/ps.sh`.

Les marqueurs comme `APP_NAME`, `APP_SLUG`, `APP_DEPOT` doivent être remplacés lorsque c’est prévu par le template.

---

## Backend

Le backend peut varier selon le projet.

Technologies possibles :

* Django / Django REST Framework
* Node.js / Express

L’agent doit détecter la technologie utilisée avant de modifier le backend.

Ne pas transformer automatiquement un backend Node.js en Django, ou inversement, sans instruction explicite.

Le backend doit exposer les routes API sous :

```text
/api
```

Exemples :

```text
/api/health
/api/auth/login
/api/auth/jwt/create
/api/contacts
/api/users
```

Les routes exactes dépendent de `specification.md`.

---

## Frontend

Le frontend est généralement une application React avec Vite.

Règles générales :

* Utiliser React.
* Utiliser Vite.
* Utiliser `VITE_API_BASE=/api`.
* Ne pas coder directement `localhost:800X` dans le frontend.
* Centraliser les appels API dans un fichier dédié, par exemple :

```text
frontend/src/api.js
```

L’interface doit rester sobre, lisible et cohérente avec les autres applications auto-hébergées du projet.

---

## Authentification

Sauf indication contraire dans `specification.md`, l’application suit ce modèle :

* Seul un administrateur peut créer des utilisateurs.
* Il n’y a pas d’écran public d’inscription.
* Les utilisateurs se connectent avec un compte créé par l’administrateur.
* L’authentification utilise un jeton JWT ou une solution équivalente.
* Les routes protégées doivent vérifier l’identité de l’utilisateur.

Le compte administrateur initial est défini par les variables :

```env
ADMIN_USERNAME
ADMIN_EMAIL
ADMIN_PASSWORD
```

Ces variables doivent provenir de `.env.local`.

---

## Rôles utilisateurs

Le modèle de base comprend au minimum :

```text
admin
user
```

Règles :

* `admin` peut gérer les utilisateurs.
* `user` peut gérer ses propres données.
* Un utilisateur ne doit pas voir les données privées d’un autre utilisateur.
* Les données publiques peuvent être visibles selon les règles définies dans `specification.md`.

---

## Données publiques et privées

Certaines applications peuvent avoir une logique de données publiques et privées.

Exemple pour une application de contacts :

* Les contacts publics peuvent être visibles normalement.
* Les contacts privés ne doivent s’afficher qu’après déverrouillage d’un coffre ou d’un mécanisme équivalent.
* Les adresses personnelles, téléphones privés et informations sensibles ne doivent pas être exposés publiquement.

Ne pas supprimer cette séparation si elle est mentionnée dans `specification.md`.

---

## Base de données

La base de données standard est PostgreSQL, sauf exception mentionnée dans `specification.md`.

Les variables PostgreSQL suivent les conventions du projet :

```env
POSTGRES_DB=${APP_SLUG}_pg_db
POSTGRES_USER=${APP_SLUG}_pg_user
POSTGRES_PASSWORD=
```

Règles :

* Ne pas utiliser `root` comme utilisateur PostgreSQL.
* Ne pas utiliser un utilisateur personnel comme `sylvain`.
* Toujours utiliser la variable `POSTGRES_USER`.
* Ne pas coder le nom de la base ou de l’utilisateur en dur si les variables existent.

---

## Production

La production est prévue pour un serveur Linode sous Ubuntu.

Le reverse proxy standard est Traefik.

Les applications sont publiées via des sous-domaines comme :

```text
${APP_SLUG}.mon-site.ca
```

Les fichiers `docker-compose.prod.yml` doivent être compatibles avec Traefik.

Les labels Traefik doivent utiliser les variables d’environnement lorsque possible.

Exemple :

```yaml
traefik.enable: "true"
traefik.http.routers.${APP_SLUG}-frontend.rule: Host(`${APP_HOST}`)
```

Ne pas supposer qu’Apache est utilisé pour les nouvelles applications.

---

## Qualité du code

Le code généré doit être :

* simple ;
* lisible ;
* maintenable ;
* cohérent avec le reste du dépôt ;
* documenté lorsque nécessaire ;
* compatible avec Ubuntu ;
* compatible avec Docker Compose.

Éviter :

* les abstractions inutiles ;
* les dépendances non nécessaires ;
* les valeurs codées en dur ;
* les modifications massives sans justification ;
* les changements de conventions existantes.

---

## Tests et validation

Après une modification importante, proposer ou exécuter les validations pertinentes.

Exemples :

```bash
./scripts/check-invariants.sh
./scripts/ps.sh
./scripts/logs.sh
docker compose --env-file .env.dev -f docker-compose.dev.yml ps
```

Pour le frontend :

```bash
cd frontend
npm install
npm run build
```

Pour un backend Node.js :

```bash
cd backend
npm install
npm test
```

Pour un backend Django :

```bash
cd backend
python manage.py check
python manage.py test
```

Adapter les commandes à la technologie réellement présente dans le projet.

---

## Git

Ne pas faire de commit automatiquement sans demande explicite.

Avant de proposer un commit, vérifier :

```bash
git status
git diff
```

Les commits doivent être clairs et atomiques.

Exemples :

```bash
git add .
git commit -m "Initialise application template"
```

Ne jamais ajouter de secrets dans Git.

---

## Ce qu’il ne faut pas faire

Ne pas :

* modifier `APP_NO` sans demande explicite ;
* commiter `.env.local` ;
* commiter `.env` si c’est un lien symbolique local non souhaité ;
* exposer des mots de passe ;
* remplacer Node.js par Django sans instruction ;
* remplacer Django par Node.js sans instruction ;
* ignorer `specification.md` ;
* coder les ports en dur ;
* coder les domaines en dur ;
* supprimer les scripts standards ;
* supprimer la séparation dev/prod ;
* changer les conventions Docker sans justification.

---

## Comportement attendu

Avant d’effectuer un changement important :

1. Lire les fichiers de référence.
2. Identifier les conventions déjà présentes.
3. Appliquer la modification minimale nécessaire.
4. Préserver la cohérence du template.
5. Valider que le projet démarre encore.
6. Résumer clairement les changements effectués.

Les réponses doivent être concrètes, orientées action, et éviter les explications inutiles.

---

## Objectif final

Ce template doit permettre de créer rapidement une nouvelle application auto-hébergée cohérente avec les autres applications du serveur `mon-site.ca`.

L’objectif est de standardiser :

* la structure des projets ;
* les fichiers d’environnement ;
* les scripts ;
* les ports ;
* les noms de services ;
* le déploiement Docker ;
* l’intégration Traefik ;
* l’authentification ;
* la documentation ;
* les futures interactions avec Codex.

## Protection des invariants globaux

`INVARIANTS.md` constitue le contrat technique canonique du projet et de l’écosystème des applications auto-hébergées.

Aucun agent ne doit modifier, supprimer, assouplir ou contourner un invariant sans autorisation explicite du propriétaire.

Lorsqu’un projet ne respecte pas un invariant, l’agent doit corriger le projet ou signaler l’écart. Il ne doit pas modifier l’invariant pour l’adapter au projet.

Toute proposition d’évolution d’un invariant doit être présentée séparément, avec sa justification, ses impacts et les migrations nécessaires. Elle ne doit jamais être appliquée automatiquement.

