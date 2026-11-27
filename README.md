# FasoSkills1 — Plateforme FasoSkills de mise en relation entre artisans et clients (T18)

> **Pitch :** FasoSkills est une plateforme mobile permettant aux particuliers au Burkina Faso de trouver rapidement des artisans locaux qualifiés (plombiers, électriciens, menuisiers), de publier des demandes de dépannage et de recevoir des devis en temps réel. Grâce aux WebSockets et à une architecture décentralisée et sécurisée, clients et artisans négocient, échangent des messages instantanés et contractualisent leurs interventions en toute confiance.

---

## 👥 Équipe et Rôles (Section 2.2)

- **Team Lead :** Coordination globale, issue board, intégration finale.
- **API Lead :** Conception de l'API REST & WebSocket, modèle de données MongoDB, sécurité & tests d'intégration.
- **App Lead :** Clean Architecture Flutter, gestion d'état BLoC, navigation déclarative `go_router`.
- **Quality Lead :** Pipeline CI/CD GitHub Actions, linters, stratégie de tests unitaires et intégration.
- **Product / UX Lead :** Parcours utilisateurs, design system, états de chargement / vide / erreur, temps réel.

---

## 🔗 Liens du Projet

- **API Déployée :** `https://api.fasoskills.bf` (ou instance Render/Railway)
- **WebSocket URL :** `wss://api.fasoskills.bf/ws`
- **Release APK :** `docs/releases/fasoskills-v1.0.0.apk`
- **Vidéo de démonstration (3 min) :** `docs/demo-video.mp4`

---

## 🚀 Comment lancer tout le projet localement en moins de 10 minutes

### Prérequis
- Node.js 24+ et npm
- Flutter 3.24+ (ou stable)
- MongoDB local ou URI MongoDB Atlas (optionnel pour les tests grâce à `mongodb-memory-server`)

### 1. Démarrer l'API Backend (`api/`)

```bash
cd api

# 1. Installer les dépendances
npm install

# 2. Remplir le fichier d'environnement (déjà pré-configuré par défaut)
cp .env.example .env

# 3. Peupler la base avec les données de démonstration et comptes de test
npm run seed

# 4. Lancer l'API en mode développement
npm run dev
```

L'API sera active sur `http://localhost:8000` et les WebSockets sur `ws://localhost:8000/ws`.

Pour exécuter la suite de tests d'intégration automatisés :
```bash
npm test
```

### 2. Démarrer l'Application Mobile Flutter (`app/`)

```bash
cd app

# 1. Récupérer les paquets
flutter pub get

# 2. Vérifier la conformité du code et exécuter les tests BLoC
flutter analyze
flutter test

# 3. Lancer l'application avec configuration via --dart-define (Exigence F13)
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api --dart-define=WS_URL=ws://127.0.0.1:8000/ws
```

---

## 🔑 Comptes de test (Peuplés via `npm run seed`)

| Rôle | Email | Mot de passe | Description |
| :--- | :--- | :--- | :--- |
| **Administrateur** | `admin@fasoskills.bf` | `Password123!` | Validation des badges artisans, modération |
| **Client** | `client1@fasoskills.bf` | `Password123!` | Publication de demandes, acceptation de devis |
| **Client** | `client2@fasoskills.bf` | `Password123!` | Évaluation d'interventions terminées |
| **Artisan** | `artisan1@fasoskills.bf` | `Password123!` | Plombier qualifié (Ouagadougou), soumission de devis |
| **Artisan** | `artisan2@fasoskills.bf` | `Password123!` | Électricien solaire (Bobo-Dioulasso) |
| **Artisan (en attente)** | `artisan3@fasoskills.bf` | `Password123!` | Menuisier à Koudougou (en attente de vérification admin) |

---

## 📋 Table des Endpoints de l'API (A13)

| Méthode | Endpoint | Rôle requis | Code Succès | Codes Erreurs | Description / Règle métier |
| :--- | :--- | :--- | :---: | :---: | :--- |
| `POST` | `/api/auth/register` | Public | 201 | 400, 409, 422 | Inscription client ou artisan |
| `POST` | `/api/auth/login` | Public | 200 | 401, 422 | Connexion avec émission de paire de tokens |
| `POST` | `/api/auth/refresh` | Public | 200 | 401 | Rotation stricte du refresh token (A6) |
| `POST` | `/api/auth/logout` | Authentifié | 200 | 400 | Révocation de la session en base |
| `GET` | `/api/auth/me` | Authentifié | 200 | 401 | Profil de l'utilisateur connecté |
| `GET` | `/api/categories` | Public | 200 | - | Liste des corps de métier actifs (`?includeInactive=true` pour Admin) |
| `POST` | `/api/categories` | Admin | 201 | 409, 422 | Création d'une catégorie de métier |
| `PATCH` | `/api/categories/:id` | Admin | 200 | 404, 409, 422 | Mise à jour d'une catégorie (dont `isActive`) |
| `DELETE` | `/api/categories/:id` | Admin | 204 | 404, 409 | Suppression d'une catégorie inutilisée |
| `GET` | `/api/artisans` | Public | 200 | 400 | Liste paginée, recherche plein texte et filtres |
| `GET` | `/api/artisans/:id` | Public | 200 | 404 | Détail complet d'un artisan et avis |
| `PUT` | `/api/artisans/:id` | Artisan/Admin | 200 | 403, 404 | Modification de son profil uniquement (A7) |
| `POST` | `/api/artisans/:id/verify` | Admin | 200 | 403, 404, 409 | Attribution du badge vérifié (T18) |
| `GET` | `/api/admin/stats` | Admin | 200 | 401, 403 | Métriques globales & graphiques (agrégation MongoDB) |
| `GET` | `/api/admin/artisans` | Admin | 200 | 401, 403, 422 | Liste paginée filtrée (`status=pending\|verified\|all`, `q`) |
| `GET` | `/api/admin/artisans/:id` | Admin | 200 | 401, 403, 404 | Détail complet artisan & pièces justificatives |
| `POST` | `/api/admin/artisans/:id/reject` | Admin | 200 | 401, 403, 404, 422 | Refus de vérification avec motif (`reason`) |
| `GET` | `/api/admin/categories` | Admin | 200 | 401, 403 | Liste complète des catégories (actives et inactives) |
| `POST` | `/api/reports` | Client/Artisan | 201 | 401, 404, 422 | Signalement d'un contenu (`request`, `review`, `message`) |
| `GET` | `/api/admin/reports` | Admin | 200 | 401, 403, 422 | Liste paginée des signalements (`type`, `status`) |
| `PATCH` | `/api/admin/reports/:id` | Admin | 200 | 401, 403, 404 | Ignorer / résoudre un signalement |
| `DELETE` | `/api/admin/content/:type/:id` | Admin | 204 | 401, 403, 404 | Suppression de contenu modéré avec motif journalisé |
| `GET` | `/api/admin/moderation-logs` | Admin | 200 | 401, 403 | Journal d'audit des actions de modération |
| `GET` | `/api/requests` | Public / Auth | 200 | 400 | Liste paginée des demandes (filtre `myOnly`) |
| `POST` | `/api/requests` | Client | 201 | 401, 422 | Création d'une demande + diffusion WebSocket |
| `PUT` | `/api/requests/:id` | Client/Admin | 200 | 403, 404 | Modification de sa propre demande uniquement |
| `DELETE` | `/api/requests/:id` | Client/Admin | 200 | 403, 404 | Annulation de sa demande |
| `POST` | `/api/quotes` | Artisan | 201 | 403, 409, 422 | Soumission de devis pour une demande |
| `GET` | `/api/quotes/request/:requestId` | Requester / Artisan | 200 | 403, 404 | Seul le client voit les devis de sa demande (T18) |
| `POST` | `/api/quotes/:id/accept` | Client | 200 | 403, 404, 409 | Acceptation unique d'un devis (T18) |
| `POST` | `/api/reviews` | Client | 201 | 403, 409, 422 | Avis uniquement pour prestation terminée (T18) |
| `GET` | `/api/reviews/artisan/:artisanId` | Public | 200 | 404 | Liste des avis reçus par l'artisan |
| `GET` | `/api/chat/conversations` | Authentifié | 200 | 401 | Liste des conversations de l'utilisateur |
| `GET` | `/api/chat/conversations/:id/messages` | Participant | 200 | 403, 404 | Historique des messages d'une discussion |
| `POST` | `/api/chat/conversations/:id/messages` | Participant | 201 | 403, 404 | Envoi d'un message + broadcast WebSocket |
| `WS` | `/ws` | Authentifié | 101 | 401 | Connexion WebSocket temps réel (devis, chat, statuts) |

---

## ⚡ Fonctionnalité Avancée (Section 3.4) : Mises à jour en temps réel (WebSockets)

- **Serveur :** Serveur WebSocket nativement intégré dans le serveur HTTP Express (`src/core/websocket/ws-server.ts`), authentifié par jeton JWT.
- **Canaux :** Canaux utilisateurs privés (`user:<userId>`) et salons de discussion (`conversation:<convId>`, `request:<requestId>`).
- **Événements temps réel :**
  - `quote:received` : Notification instantanée au client dès qu'un artisan soumet un devis.
  - `quote:accepted` : Alerte temps réel à l'artisan lorsque son offre est retenue.
  - `message:received` : Réception instantanée des messages de discussion sans rechargement.
  - `request:updated` : Mise à jour synchronisée des statuts d'intervention.

---

## 🛡️ Règles de Sécurité et Architecture

1. **Aucun secret dans le dépôt :** Les clés privées sont injectées par variables d'environnement (`.env`), validées au démarrage par un schéma **Zod**.
2. **Autorisations au niveau objet (A7) :** Un client ne peut ni modifier ni annuler les demandes d'un autre client ; un artisan ne peut modifier que son propre profil ; les devis d'une demande ne sont visibles que par l'auteur de la demande.
3. **Gestion d'état BLoC / Clean Architecture (F1, F2) :** Découpage strict `domain` (pur Dart, sans dépendance framework), `data` (repositories, clients HTTP/WS), `presentation` (BLoCs, écrans).
4. **Mises à jour optimistes (F8) :** L'annulation d'une demande met à jour l'interface instantanément avec mécanisme automatique de *rollback* si l'appel réseau échoue.
5. **Stratégie Cache then Network (F9) :** Le flux des artisans et les catégories sont mis en cache localement pour permettre un démarrage instantané même hors-ligne.
6. **Rafraîchissement concurrent-safe des tokens (F6) :** En cas d'échecs 401 simultanés sur plusieurs requêtes, une seule demande de refresh est émise, les autres attendent son résultat et sont rejouées.

---

## ⚠️ Limitations connues

- Le système de géolocalisation utilise pour l'instant un filtrage par ville (`Ouagadougou`, `Bobo-Dioulasso`, etc.) et adresse textuelle ; le calcul GPS direct par index 2dsphere peut être étendu.
- Le stockage des photos est configuré en URLs directes / base64 ; l'intégration d'un bucket S3 avec signed URLs est prête à être branchée pour la production.
