# **APP_NAME** — README_DEV

Application basée sur les invariants standards du template applicatif.

Ce fichier décrit le démarrage local en développement.

---

## Démarrage rapide

Depuis la racine du projet :

```bash
make init
```

Le `Makefile` est la méthode recommandée pour les commandes courantes. Il délègue aux scripts standards du projet, qui restent la source de vérité.

`make init` appelle :

```bash
./scripts/init.sh dev
```

Ce script initialise le projet, prépare les fichiers d’environnement, valide les invariants et démarre les services Docker.

---

## Commandes courantes

### Aide

```bash
make help
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

### Arrêter

```bash
make down
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

Rôle des fichiers :

```text
.env.dev      Variables non secrètes pour le développement
.env.prod     Variables non secrètes pour la production
.env.local    Secrets locaux non versionnés
.env          Lien symbolique vers .env.dev ou .env.prod
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

---

## Génération des environnements

Normalement, cette étape est faite automatiquement par :

```bash
make init
```

En cas de besoin :

```bash
./scripts/generate-env.sh
```

Les secrets sont générés par :

```bash
./scripts/generate-secrets.sh
```

---

## Validation

Pour vérifier que le projet respecte les invariants :

```bash
make check
```

---

## Règle importante

Les commandes Docker Compose ne devraient pas être tapées directement dans l’usage courant.

Utiliser le `Makefile`, qui appelle les scripts standards :

```bash
make init
make up
make down
make logs
make ps
```

---

## Notes pour Codex

Codex doit respecter les règles suivantes :

* ne pas modifier `APP_NO` sans demande explicite ;
* ne pas écrire de secret dans Git ;
* ne pas hardcoder les ports ;
* utiliser les scripts standards ;
* respecter `INVARIANTS.md` ;
* conserver `.env.local` hors versionnement.

---

## Démarrage manuel équivalent

À titre informatif seulement, `./scripts/init.sh` remplace normalement cette séquence :

```bash
./scripts/generate-env.sh
./scripts/env-switch.sh dev
./scripts/check-invariants.sh
./scripts/up.sh
```
