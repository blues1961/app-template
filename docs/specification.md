# Spécification du projet

## 1. Objectif

Décrire clairement ce que fait l’application, son but principal et la valeur apportée.

> Exemple :
> Application web permettant de gérer des contacts personnels avec distinction public/privé.

---

## 2. Utilisateurs

Définir les types d’utilisateurs :

- Admin
- Utilisateur standard (si applicable)

Préciser :
- leurs permissions
- leurs actions principales

---

## 3. Portée du MVP

### 3.1 Fonctionnalités principales (MVP)

Lister uniquement ce qui est essentiel :

- Authentification utilisateur (login)
- Création d’un élément
- Consultation (liste)
- Modification
- Suppression
- Persistance en base de données
- Communication frontend ↔ backend via `/api`

---

### 3.2 Critères d’acceptation du MVP

Le MVP est considéré comme fonctionnel lorsque :

- L’utilisateur peut se connecter avec succès
- Les données sont enregistrées et récupérées correctement
- Toutes les opérations CRUD fonctionnent
- L’API répond correctement (200, 400, 401, etc.)
- Le frontend affiche les données sans erreur

---

## 4. Hors MVP (Backlog)

Fonctionnalités prévues mais non prioritaires :

- Fonctionnalité 1
- Fonctionnalité 2
- Améliorations UX
- Optimisations

---

## 5. Données (Modèle métier)

Décrire les entités principales :

- Entité 1
- Entité 2

Relations :
- 1 → N
- N → N

Exemple :
- User → PasswordEntry (1:N)
- Category → PasswordEntry (1:N)

---

## 6. Règles métier

Définir clairement :

### Autorisé
- Ce que l’utilisateur peut faire

### Interdit
- Ce qui est bloqué

### Cas particuliers
- Ex : données privées visibles seulement si coffre déverrouillé

---

## 7. Flux utilisateur

Décrire les parcours principaux :

### Exemple :
1. L’utilisateur arrive sur login
2. Il s’authentifie
3. Il accède au dashboard
4. Il consulte / crée / modifie des éléments

---

## 8. Frontend (UI)

Écrans minimum :

- Login
- Dashboard
- Liste des éléments
- Formulaire création / édition

Optionnel :
- Messages d’erreur
- Loader / état de chargement

---

## 9. Backend (API)

### 9.1 Structure

- Base URL : `/api`
- Format : JSON
- Auth : JWT

---

### 9.2 Routes principales

Exemple :

- POST `/api/auth/login`
- GET `/api/items`
- POST `/api/items`
- PUT `/api/items/:id`
- DELETE `/api/items/:id`

---

### 9.3 Permissions

- Auth requise pour toutes les routes (sauf login)
- Isolation des données par utilisateur

---

## 10. Contraintes techniques

- Backend : (Django / Node / autre)
- Frontend : (React / Vite)
- Base de données : PostgreSQL
- Conteneurisation : Docker Compose
- Environnement : `.env`

---

## 11. Structure attendue du projet

Référencer les conventions :

- `frontend/`
- `backend/`
- `docker-compose.dev.yml`
- `docker-compose.prod.yml`
- `scripts/`

---

## 12. Hypothèses et limites

- Application mono-utilisateur ou multi-utilisateur ?
- Données sensibles ?
- Besoin de chiffrement ?

---

## 13. Notes pour Codex / Agent

- Respecter les invariants du projet
- Ne pas modifier les fichiers `.env`
- Utiliser `/api` comme base
- Respecter la structure Docker existante