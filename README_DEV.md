# **APP_NAME** — README_DEV

Application basée sur les invariants standards du template applicatif.

Ce fichier décrit le démarrage local en développement.

---

## Démarrage rapide

Depuis la racine du projet :

```bash
./scripts/init.sh
```

Ce script initialise le projet, prépare les fichiers d’environnement, valide les invariants et démarre les services Docker.

---

## Commandes courantes

### Voir l’état des services

```bash
./scripts/ps.sh
```

### Voir les logs

```bash
./scripts/logs.sh
```

Ou pour un service précis :

```bash
./scripts/logs.sh backend
./scripts/logs.sh frontend
./scripts/logs.sh db
```

### Redémarrer

```bash
./scripts/restart.sh
```

### Arrêter

```bash
./scripts/down.sh
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
./scripts/env-switch.sh dev
```

### Production

```bash
./scripts/env-switch.sh prod
```

---

## Génération des environnements

Normalement, cette étape est faite automatiquement par :

```bash
./scripts/init.sh
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
./scripts/check-invariants.sh
```

---

## Règle importante

Les commandes Docker Compose ne devraient pas être tapées directement dans l’usage courant.

Utiliser les scripts standards :

```bash
./scripts/init.sh
./scripts/up.sh
./scripts/down.sh
./scripts/logs.sh
./scripts/ps.sh
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
