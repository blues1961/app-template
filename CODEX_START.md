# CODEX_START.md

## Mandat initial pour Codex

Tu travailles dans un dépôt d’application auto-hébergée généré à partir du template standard de Sylvain.

Ton objectif est de transformer ce squelette de projet en une application fonctionnelle, cohérente avec les conventions du template, sans casser les invariants existants.

Avant toute modification, lis attentivement les fichiers suivants à la racine du projet :

* `AGENTS.md`
* `INVARIANTS.md`
* `README.md`
* `README_DEV.md`
* `specification.md`
* `.env.template`
* `.env.dev`
* `.env.prod`
* `.env.local` si présent, sans afficher ni commiter son contenu
* `docker-compose.dev.yml`
* `docker-compose.prod.yml`

---

## Règles prioritaires

### 1. Respecter les invariants du template

Ne modifie jamais inutilement les conventions globales du projet.

En particulier :

* ne change pas `APP_SLUG` sans demande explicite ;
* ne change pas `APP_NO` sans demande explicite ;
* ne change pas la stratégie des ports dérivés de `APP_NO` ;
* ne remplace pas la convention `.env.dev`, `.env.prod`, `.env.local` ;
* ne commit jamais de secrets ;
* ne déplace pas les secrets hors de `.env.local` ;
* ne remplace pas `docker compose` par l’ancienne syntaxe `docker-compose` ;
* utilise toujours `--env-file` dans les commandes Docker Compose ;
* conserve la séparation dev/prod.

Les fichiers `.env.dev` et `.env.prod` doivent rester versionnables s’ils ne contiennent pas de secrets.

Le fichier `.env.local` est local, privé et non commité.

---

## Stack attendue

Le projet suit une architecture standard d’application auto-hébergée :

* frontend React/Vite ;
* backend selon le template du projet ;
* base PostgreSQL sauf si la spécification indique clairement qu’aucune base n’est requise ;
* Docker Compose pour le développement et la production ;
* Traefik en production ;
* fichiers d’environnement séparés pour dev et prod ;
* scripts de gestion dans `scripts/`.

Tu dois adapter le code au contenu réel de `specification.md`.

Si `specification.md` décrit une application de contacts, de calendrier, de pense-bête, de météo ou une autre application, la spécification a priorité sur les suppositions génériques.

---

## Commandes Docker à utiliser

En développement, utilise la forme suivante :

```bash
docker compose --env-file .env.dev -f docker-compose.dev.yml ps
```

Exemples :

```bash
docker compose --env-file .env.dev -f docker-compose.dev.yml up -d --build
```

```bash
docker compose --env-file .env.dev -f docker-compose.dev.yml logs -f
```

```bash
docker compose --env-file .env.dev -f docker-compose.dev.yml down
```

En production, utilise la forme suivante :

```bash
docker compose --env-file .env.prod -f docker-compose.prod.yml ps
```

Ne propose pas de commande sans `--env-file`, sauf si tu expliques clairement pourquoi.

Pour l’usage courant du projet, préfère toutefois les scripts standards et les cibles `make` déjà présentes plutôt que des commandes Docker Compose retapées à la main.

Commandes usuelles :

```bash
make up
make down
make rebuild
make migrate
make backup
make restore
make update
make ps
```

---

## Objectif de départ

Commence par produire un MVP propre et fonctionnel.

Le MVP doit inclure :

1. une application qui démarre correctement en Docker ;
2. un frontend accessible sur le port de développement défini par les variables d’environnement ;
3. un backend accessible via `/api` ;
4. une route de santé backend, par exemple `/api/health` ;
5. une authentification minimale si demandée par la spécification ;
6. un compte administrateur géré à partir des variables d’environnement ;
7. les écrans et endpoints nécessaires au cœur du MVP ;
8. un écran de login cohérent avec le thème commun dans `docs/THEME.md` ;
9. une documentation mise à jour ;
10. des scripts fonctionnels dans `scripts/` ;
11. une vérification finale avec les commandes Docker Compose appropriées.

---

## Authentification et gestion des utilisateurs

Par défaut, les applications auto-hébergées de Sylvain suivent cette approche :

* il n’y a pas d’inscription publique ;
* seul l’administrateur peut créer des utilisateurs ;
* les utilisateurs se connectent avec un compte créé par l’administrateur ;
* chaque utilisateur possède ses propres données ;
* les données privées d’un utilisateur ne doivent pas être visibles par les autres utilisateurs ;
* le compte admin initial est défini par les variables :

  * `ADMIN_USERNAME`
  * `ADMIN_EMAIL`
  * `ADMIN_PASSWORD`

Ces variables se trouvent dans `.env.local` ou sont injectées par l’environnement.

Ne les affiche jamais dans les logs, la documentation ou les messages de commit.

---

## Données publiques et privées

Si l’application gère des données publiques et privées, respecte les principes suivants :

* une donnée publique peut être visible selon les règles définies dans `specification.md` ;
* une donnée privée ne doit être visible que par son propriétaire ou par un rôle explicitement autorisé ;
* le frontend ne doit pas recevoir de données privées si l’utilisateur n’a pas le droit de les voir ;
* le masquage visuel côté frontend ne suffit pas pour protéger une donnée ;
* les règles d’accès doivent être appliquées côté backend.

Pour une application de contacts, par exemple :

* les contacts publics peuvent être visibles dans une liste générale ;
* les contacts privés ne doivent apparaître que lorsque l’utilisateur autorisé y a accès ;
* les champs sensibles comme adresse, téléphone personnel, courriel personnel ou notes privées doivent être protégés côté API.

---

## Sécurité

Respecte ces règles minimales :

* ne commit aucun secret ;
* ne log aucun mot de passe ;
* ne log aucun token JWT complet ;
* ne stocke pas de mot de passe en clair ;
* valide les entrées côté backend ;
* applique l’isolation des données par utilisateur ;
* évite les permissions trop larges ;
* garde les dépendances minimales ;
* évite les changements massifs non nécessaires.

Si tu dois ajouter une dépendance, justifie-la brièvement dans ton résumé final.

---

## Travail attendu par étapes

Procède dans cet ordre :

1. lire les fichiers de contexte ;
2. identifier le type d’application à construire ;
3. vérifier les variables d’environnement et les ports ;
4. vérifier les services Docker Compose ;
5. implémenter ou corriger le backend ;
6. implémenter ou corriger le frontend ;
7. connecter le frontend au backend via `/api` ;
8. ajouter ou corriger les scripts utiles ;
9. mettre à jour la documentation ;
10. exécuter les tests ou au minimum les commandes de validation disponibles ;
11. produire un résumé clair des changements.

---

## Workflow opératoire standard

Quand le template fournit déjà les scripts de maintenance, n’invente pas un workflow parallèle.

Règles :

* pour démarrer ou relancer les services, utiliser `make up`, `make down`, `make restart`, `make ps` ;
* pour les migrations Django, utiliser `make migrate` ;
* pour un backup PostgreSQL, utiliser `make backup` ;
* pour une restauration PostgreSQL, utiliser `make restore` ;
* pour une mise à jour applicative complète, utiliser `make update` ;
* si un comportement change, mettre à jour `README.md` et `README_DEV.md`.

Séquence standard de mise à jour :

1. `make backup`
2. `git pull --ff-only`
3. `make check`
4. `make rebuild`
5. `make up`
6. `make migrate`
7. `make ps`

Ne remplace pas cette séquence par `make rebuild` seul : la reconstruction des images ne redémarre pas automatiquement les conteneurs.

Restauration PostgreSQL :

* considérer `make restore` comme destructif ;
* le script recrée le schéma `public` avant import ;
* il faut éviter de lancer une restauration sans prévenir clairement l’utilisateur ;
* après une restauration, vérifier l’état des services et exécuter des validations pertinentes si nécessaire.

---

## Ce qu’il ne faut pas faire

Ne fais pas les actions suivantes sans demande explicite :

* supprimer la structure du template ;
* renommer l’application ;
* changer `APP_SLUG` ;
* changer `APP_NO` ;
* changer les ports manuellement sans respecter la convention ;
* remplacer Traefik par Apache ou Caddy dans l’application ;
* ajouter une inscription publique ;
* exposer les secrets ;
* commiter `.env.local` ;
* ignorer `AGENTS.md` ;
* ignorer `INVARIANTS.md` ;
* réécrire toute l’architecture si une correction ciblée suffit.

---

## Attentes pour le frontend

Le frontend doit être simple, lisible et fonctionnel.

Préférences générales :

* React avec Vite ;
* interface en français ;
* style sobre, propre et cohérent avec les autres applications auto-hébergées ;
* appels API centralisés autant que possible ;
* gestion claire de l’état de connexion ;
* messages d’erreur compréhensibles ;
* aucune donnée privée affichée sans autorisation.

Le frontend doit utiliser `/api` comme base d’API lorsque le template le prévoit.

---

## Attentes pour le backend

Le backend doit fournir une API claire et testable.

Préférences générales :

* routes sous `/api` ;
* route de santé `/api/health` ;
* authentification par token ou JWT selon le template ;
* validation des données ;
* séparation claire entre routes, modèles, contrôleurs et logique métier ;
* accès aux données filtré par utilisateur ;
* endpoints documentés sommairement dans le README ou la documentation de développement.

Si le backend est en Node/Express, garde une structure simple et maintenable.

Si le backend est en Django, respecte les conventions Django/DRF du projet.

---

## Attentes pour PostgreSQL

Si PostgreSQL est utilisé :

* utilise les variables d’environnement existantes ;
* ne code pas les identifiants en dur ;
* respecte `POSTGRES_USER`, `POSTGRES_DB` et `POSTGRES_PASSWORD` ;
* prévois les migrations ou scripts nécessaires ;
* assure-toi que le backend attend correctement la disponibilité de la base ;
* ne supprime pas les volumes sans demande explicite.

---

## Documentation à maintenir

Mets à jour la documentation lorsque tu changes le comportement du projet.

Fichiers à considérer :

* `README.md` : vue d’ensemble, usage général, déploiement sommaire ;
* `README_DEV.md` : procédure de développement locale, backup, restore, migrate et update ;
* `specification.md` : ne pas modifier sauf si demandé ;
* `INVARIANTS.md` : ne modifier que si une convention officielle change ;
* `AGENTS.md` : ne modifier que si les règles de travail de l’agent changent.

La documentation doit rester concrète et alignée avec les commandes réelles du projet.

---

## Validation minimale avant de terminer

Avant de conclure, tente de valider le projet avec les commandes disponibles.

Exemples :

```bash
docker compose --env-file .env.dev -f docker-compose.dev.yml ps
```

```bash
docker compose --env-file .env.dev -f docker-compose.dev.yml logs --tail=100
```

Si les services doivent être reconstruits :

```bash
docker compose --env-file .env.dev -f docker-compose.dev.yml up -d --build
```

Si des tests existent, exécute-les.

Si aucun test n’existe, indique-le clairement dans le résumé final.

---

## Résumé final attendu

À la fin de ton intervention, fournis un résumé clair comprenant :

* les fichiers modifiés ;
* les fonctionnalités ajoutées ou corrigées ;
* les commandes exécutées ;
* les résultats observés ;
* les tests effectués ;
* les limites restantes ;
* les prochaines étapes recommandées.

Sois précis. Ne masque pas les erreurs. Si une commande échoue, indique la cause probable et propose une correction.

---

## Rappel important

Ce dépôt sert à produire une application auto-hébergée fiable, maintenable et cohérente avec les autres applications de Sylvain.

La priorité est la stabilité du template, la cohérence des invariants, la sécurité des secrets et la livraison progressive d’un MVP fonctionnel.

## Règle absolue sur les invariants

Avant toute modification, lire `INVARIANTS.md`.

Les invariants globaux sont protégés. Tu ne dois jamais les modifier, les supprimer, les assouplir ou les contourner sans autorisation explicite du propriétaire.

Si le code contredit un invariant, corrige le code. Ne modifie pas l’invariant pour justifier l’état actuel du projet.

Une évolution possible d’un invariant doit être présentée comme une proposition distincte et ne doit pas être appliquée sans validation explicite.


---

## Matérialisation du template

Le cycle de vie du dépôt appartient à `app-template`.

Règles :

* la matérialisation d’une copie du modèle s’effectue avec `APP_TEMPLATE_MATERIALIZE=1 make init` ;
* le détachement Git n’est autorisé que si `APP_TEMPLATE_DETACH_GIT=1` est fourni explicitement ;
* les métadonnées canoniques sont `.app-template/template.json` pour le dépôt source et `.app-template/origin.json` pour une application matérialisée ;
* DocForge est une intégration facultative de lecture et ne doit pas être requis pour créer ou vérifier l’application ;
* les variables historiques `DOCFORGE_*` ne relèvent plus du flux principal et ne doivent être conservées qu’en compatibilité héritée.
