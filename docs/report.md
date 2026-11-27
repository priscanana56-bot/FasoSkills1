# FasoSkills — Final Engineering Report (Milestone 4)

## 1. Vue d'ensemble du produit
FasoSkills répond à la problématique de la mise en relation entre artisans de proximité et particuliers au Burkina Faso. L'application propose un flux complet : recherche d'artisans, publication de besoins, réception et acceptation de devis chiffrés, échanges via messagerie instantanée WebSockets et notation finale.

## 2. Architecture de l'API et de l'Application
- **API Backend :**
  - Architecture en couches strictes : `routes` ➔ `controllers` ➔ `services` ➔ `models`.
  - Contrôle des types statiques avec TypeScript et validation des requêtes avec Zod (rejet des champs inconnus).
  - Serveur WebSocket intégré partageant le même serveur HTTP pour les notifications temps réel.
- **Application Flutter :**
  - **Clean Architecture Feature-First :** chaque fonctionnalité (`auth`, `artisans`, `requests`, `chat`) isole son `domain` (pur Dart, sans dépendance), son `data` et sa `presentation`.
  - **BLoC & Cubit :** Gestion d'état prédictible, sans logique métier dans les widgets.
  - **Injection de dépendances :** Point de composition unique avec `GetIt`.
  - **Navigation déclarative :** Route guard avec `go_router` piloté par l'état d'authentification.

## 3. Sécurité & Défenses OWASP API
- **Stockage des mots de passe :** Hachage fort avec bcrypt (10 rounds de sel).
- **Cycle de vie des tokens :** Tokens d'accès courts (15 min) et jetons de rafraîchissement avec rotation stricte en base (A6).
- **Protection contre les attaques de force brute :** Rate limiter configurable sur les routes d'authentification (`express-rate-limit`).
- **En-têtes de sécurité :** Intégration de `helmet` pour la protection contre le clickjacking et l'injection de scripts.
- **Contrôle d'accès au niveau objet (BOLA / Broken Object Level Authorization) :**
  - Un utilisateur ne peut pas modifier ni supprimer la demande d'un autre utilisateur.
  - Seul le client auteur de la demande peut visualiser l'ensemble des devis soumis.
  - Les avis ne peuvent être déposés que pour des interventions terminées (`status: completed`).

## 4. Gestion d'État et Mises à Jour Optimistes (F8)
- **BLoC `RequestBloc` :**
  - Lorsqu'un utilisateur annule une demande, l'état `RequestLoaded` est immédiatement émis avec le statut `cancelled` (mise à jour optimiste).
  - La requête API est exécutée en arrière-plan. En cas de panne réseau ou de refus serveur, le BLoC effectue un *rollback* automatique vers l'état antérieur et notifie l'utilisateur.
- **BLoC `ArtisanListBloc` :**
  - Implémente l'event transformer `debounce` (300 ms) pour éviter de saturer l'API lors de la saisie dans la barre de recherche.
  - Stratégie `Cache-then-network` : affichage immédiat des artisans mis en cache lors d'un lancement hors-ligne.

## 5. Fonctionnalité Avancée : WebSockets
- Implémentation d'un serveur WebSocket bidirectionnel sous Express 5.
- Notification instantanée lors de la création d'un devis (`quote:received`), de son acceptation (`quote:accepted`) et des messages du chat (`message:received`).
