# PLAN DE RÉPARTITION OFFICIEL DES TÂCHES — PROJET FASOSKILLS (T18)
## Conforme aux Directives de l'Équipe et aux Exigences du Professeur
**Cours :** Advanced Mobile Development – Year 3 (BIT)  
**Enseignant référent :** Dr Lebian Wilfried NIKIEMA  
**Équipe :** Cédric, Aman, Prisca, Grace  

---

## 1. Nouvelle Répartition Validée de l'Équipe

La répartition des responsabilités repose désormais sur la structure suivante :

| Membre | Rôle & Périmètre Attribué | Technologies |
| :--- | :--- | :--- |
| **CÉDRIC** | **Frontend Client & Frontend Agent (Artisan)** | Flutter / Dart (Mobile) |
| **AMAN** | **Frontend Administrateur & Backend UNIQUEMENT Administrateur** | Flutter/Web & Node.js/Express (Admin) |
| **PRISCA** | **Backend Client & Backend Agent (Artisan)** + **Communication avec le Backend Administrateur** | Node.js / Express 5 / MongoDB / WebSockets |
| **GRACE** | **Documentation Complète & Livrables Académiques (M1, M4, Slides)** | LaTeX / Markdown / PDF / Vidéo Démo |

---

## 2. Détail des Tâches & Livrables Concrets par Membre

### 👤 1. CÉDRIC — *Frontend Client & Frontend Agent (Artisan)*
- **Espace Client :**
  - Écran d'accueil FasoSkills (carrousel hero 3 cartes, 4 services mis en avant, actions rapides).
  - Remplacement de « Recent Projects » par « Artisans disponibles » avec notes et localisation.
  - Page dédiée de listing des professionnels avec barre de recherche et filtres par corps de métier.
  - Page profil artisan détaillée (avis vérifiés, réalisations/portfolio, tarifs indicatifs, boutons d'action rapide).
  - Formulaire « Nouvelle demande » (sélection de métier, date, créneau horaire, budget indicatif, photos).
  - Onglet « Discussions » avec liste des conversations et vue de chat en direct.
  - Écran dédié de notifications système et alertes chantiers.
- **Espace Agent (Artisan) :**
  - Consultation des demandes d'intervention disponibles dans sa zone géographique.
  - Interface de soumission et envoi d'un devis chiffré.
  - Suivi et mise à jour des statuts de chantier (`accepted` ➔ `in_progress` ➔ `completed`).
- **Architecture Flutter & Qualité :**
  - Architecture Clean Architecture Feature-First (`domain`, `data`, `presentation`).
  - Gestion d'état BLoC : `RequestBloc` (avec optimistic update et rollback), `ArtisanListBloc` (avec debounce 300ms).
  - Gestion des 4 états UI obligatoires : Chargement, Vide, Erreur avec bouton réessai, Données chargées.
  - Navigation déclarative sécurisée avec `go_router` et Route Guards d'authentification.
  - Tests unitaires et tests de BLoC Flutter (`app/test/bloc_test.dart`).
  - Génération de l'APK Release (`v1.0.0`) testé sur smartphone réel.

---

### 👤 2. AMAN — *Frontend Administrateur & Backend UNIQUEMENT Administrateur*
- **Frontend Administrateur :**
  - Dashboard web/mobile pour la supervision globale du système FasoSkills.
  - Interface de modération des utilisateurs (clients et artisans).
  - Interface de gestion du catalogue des catégories et corps de métier.
- **Backend Administrateur :**
  - Routes et contrôleurs d'administration : `/api/admin/users`, `/api/admin/categories`, `/api/admin/artisans/:id/verify`.
  - Workflow d'attribution et révocation du badge « Artisan Vérifié FasoSkills ».
  - Activation, suspension ou bannissement des comptes frauduleux.
  - Sécurisation stricte de l'accès aux endpoints admin via middleware RBAC (`requireRole('admin')`).
- **Communication avec le Backend Métier :**
  - Mise à disposition des statuts de vérification des artisans pour alimenter les listes publiques.

---

### 👤 3. PRISCA — *Backend Client & Backend Agent (Artisan) + Passerelle Admin*
- **Backend Métier Client & Agent :**
  - **Gestion des demandes (`jobRequests`) :** Création de demande avec photos, critères d'urgence et adresse d'intervention.
  - **Gestion des devis (`quotes`) :** Envoi d'un devis par un artisan, consultation des devis par le demandeur.
  - **Gestion des avis (`reviews`) :** Dépôt de notation et commentaire avec calcul automatique de la note moyenne de l'artisan.
  - **Recherche & Filtres :** Requêtes MongoDB avec filtres de catégorie, ville et quartier.
- **Règles Serveur Strictes du Sujet T18 :**
  - **Contrôle d'accès BOLA :** Seul le client auteur d'une demande a le droit de voir les devis qui lui sont soumis.
  - **Atomicité d'acceptation :** Un seul devis accepté par demande (verrouillage immédiat pour éviter toute collision concurrente).
  - **Avis conditionnés :** Dépôt d'avis vérifié autorisé uniquement pour une intervention au statut `completed`.
- **Communication avec le Backend Administrateur :**
  - Consommation des statuts d'artisans validés par Aman pour afficher le badge certifié côté Client.
  - Remontée des métriques globales d'activité (nombre d'interventions, chiffre d'affaires moyen) vers l'espace Admin.
- **WebSockets & Tests API :**
  - Implémentation du serveur WebSocket (`ws-server.ts`) pour les notifications en temps réel (`quote:received`, `message:received`).
  - Rédaction de la suite de tests d'intégration API (`supertest`) couvrant l'authentification, les permissions et les règles BOLA.

---

### 👤 4. GRACE — *Documentation Complète & Livrables Académiques*
- **Design Document M1 (`docs/design.pdf`) :**
  - Document de 6 à 10 pages complet : Problème, 10 à 20 User Stories prioritaires (MoSCoW), Modèle MongoDB (décisions embed vs ref justifiées), Table des endpoints REST, Wireframes, Diagrammes d'architecture, Matrice des risques techniques.
- **Rapport Final d'Ingénierie M4 (`docs/report.pdf`) :**
  - Document de 10 à 15 pages rédigé pour un ingénieur reprenant le projet :
    1. Présentation du produit avec captures d'écran.
    2. Architecture API et App (justification des choix par rapport au lab).
    3. Tableau de sécurité et correspondance avec le Top 10 OWASP API.
    4. Analyse détaillée de 2 BLoCs (événements, états, transformers).
    5. Stratégie de tests automatisés.
    6. Fonctionnalité avancée (WebSockets temps réel).
    7. Les 3 décisions techniques qu'on prendrait différemment aujourd'hui.
    8. **Paragraphe individuel rédigé par chaque membre (Cédric, Aman, Prisca, Grace)** avec liens vers leurs PRs.
- **Supports de Soutenance & Release :**
  - Conception du diaporama officiel pour la présentation orale de 25 minutes (`docs/slides.pdf`).
  - Élaboration du jeu de données de test burkinabè réaliste pour le seed (`seed.ts`).
  - Coordination et montage de la vidéo de démonstration de 3 minutes.
  - Audit de l'historique Git (`git log -p`) pour garantir l'absence totale de secrets commis.

---

## 3. Matrice de Répartition Face au Barème de Dr NIKIEMA (100 Points)

| Critère d'Évaluation | Points | Ce qui est Livré | Responsables Directs |
| :--- | :---: | :--- | :--- |
| **Sécurité API** | 15 pts | JWT rotation, hash bcrypt, contrôle BOLA strict, RBAC admin/client/artisan, rate limiting. | **Prisca & Aman** |
| **Architecture App Flutter** | 15 pts | Clean Architecture, injection `get_it`, contrats de repositories, route guards `go_router`. | **Cédric** |
| **Gestion d'état BLoC** | 10 pts | `RequestBloc` (optimistic update & rollback), `ArtisanListBloc` (debounce 300ms), 4 états UI. | **Cédric** |
| **Tests & Pipeline CI/CD** | 10 pts | Tests d'intégration API (`supertest`), tests de BLoC (`bloc_test`), workflow GitHub Actions vert. | **Prisca & Cédric** |
| **Produit & UX** | 10 pts | Complétude des flux T18, design pro, gestion du mode hors-ligne (*Cache-then-network*). | **Cédric & Grace** |
| **Fonctionnalité Avancée** | 5 pts | WebSockets bidirectionnels temps réel (alertes devis et chat direct). | **Prisca & Cédric** |
| **Documentation & Rapport** | 10 pts | Design Doc M1, README (&lt; 10 min), Rapport final M4 avec paragraphes individuels. | **Grace** |
| **Soutenance (25 minutes)** | 10 pts | 3 min setup + 7 min slides (tous parlent) + 7 min démo live multi-rôles + 8 min questions jury. | **Toute l'équipe** |
| **Bonus (+5 max)** | +5 pts | Déploiement Web, qualité UX exceptionnelle et tests de bout en bout supplémentaires. | **Toute l'équipe** |

---

## 4. Déroulement Chronométré de la Soutenance (25 Minutes)

| Timing | Étape | Intervenants | Contenu Présenté |
| :---: | :--- | :--- | :--- |
| **00:00 – 03:00** | Installation & Setup | Cédric & Prisca | Connexion du smartphone au vidéoprojecteur, vérification de l'API déployée et des données de seed. |
| **03:00 – 10:00** | Présentation Slides (7 min) | **Les 4 membres** (~1m45 chacun) | • **Grace :** Problématique locale T18 au Burkina Faso, personas et objectifs du produit.<br>• **Aman :** Module Administrateur, modération des artisans et sécurité d'accès RBAC.<br>• **Prisca :** Backend Client/Agent, modèle MongoDB, sécurité OWASP & BOLA.<br>• **Cédric :** Clean Architecture Flutter, gestion d'état BLoC, UX des parcours Client & Artisan. |
| **10:00 – 17:00** | Démo Live Multi-Rôles (7 min) | Cédric (Client) & Prisca (Artisan) & Aman (Admin) | **Scénario réaliste en direct :**<br>1. Cédric publie une « Nouvelle demande » de plomberie sur son iPhone.<br>2. Prisca reçoit la demande via WebSocket et envoie un devis chiffré.<br>3. Cédric reçoit l'alerte en direct et accepte le devis.<br>4. Aman présente le tableau de bord Admin pour valider le badge de l'artisan. |
| **17:00 – 25:00** | Questions du Jury (8 min) | Réponses individuelles ciblées | Questions techniques de Dr NIKIEMA posées individuellement à chaque étudiant sur son code. |
