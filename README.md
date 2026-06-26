# 🚌 FasoTransport — Système de Gestion et de Réservation de Transports Interurbains

FasoTransport est une plateforme complète et moderne dédiée à la gestion, la planification et la réservation de trajets de bus interurbains au Burkina Faso. Ce projet est structuré sous forme de monorepo contenant un backend NestJS, un dashboard d'administration Web (Next.js), et une application mobile multiplateforme (Flutter).

---

## 🏗️ Architecture du Projet

Le dépôt est organisé en trois composants principaux :

```mermaid
graph TD
    A[Mobile App - Flutter] -->|API REST| B[Backend API - NestJS]
    C[Web Dashboard - Next.js] -->|API REST| B
    B -->|TypeORM| D[(PostgreSQL)]
    B -->|Gemini API| E[Google Generative AI]
```

### 1. 🖥️ Backend (`/backend`)
API REST robuste construite avec **NestJS** et **TypeScript**.
* **Base de données** : PostgreSQL (avec support de migration depuis MongoDB).
* **ORM** : TypeORM.
* **Sécurité** : Authentification par jetons JWT (Access Token & Refresh Token) et hachage de mots de passe via `bcrypt`.
* **Services** :
  * Génération de codes QR pour les billets de transport.
  * Chatbot intelligent intégré basé sur **Google Generative AI (Gemini)**.
  * Script d'initialisation de base de données (Seed) et script de migration MongoDB vers PostgreSQL.

### 2. 🌐 Frontend (`/frontend`)
Panneau d'administration web conçu avec **Next.js**, **React**, et **TailwindCSS**.
* **Fonctionnalités** :
  * Tableau de bord récapitulatif des revenus, des réservations et du taux d'occupation.
  * Gestion complète des lignes de bus (Création, modification, détails et suppression).
  * **Calcul Intelligent** : Calcul automatique de la distance routière et du temps de trajet estimé dès la saisie des villes à l'aide de l'API *OSRM* et *OpenStreetMap (Nominatim)*.
  * Planification des horaires, assignation des agents de terrain et suivi des bus disponibles.

### 3. 📱 Application Mobile (`/mobile`)
Application mobile développée avec **Flutter** servant deux profils d'utilisateurs distincts :
* **Espace Passager** :
  * Recherche de trajets par date et villes (Ouagadougou, Bobo-Dioulasso, Koudougou...).
  * Sélection interactive des sièges sur le plan du bus.
  * Simulation de paiement via Orange Money & Moov Money.
  * Visualisation du billet QR et génération de PDF pour partage immédiat.
  * Support voyageur intégré avec l'agent conversationnel AI (TransChat).
* **Espace Agent Terrain** :
  * Liste des trajets assignés de la journée.
  * Scanner de code QR ultra-rapide (via `mobile_scanner`) pour le contrôle et la validation instantanée des billets à l'embarquement.
  * Gestion robuste des sessions avec déconnexion automatique en cas de jeton invalide (erreur HTTP 401).

---

## 🚀 Démarrage Rapide & Installation

### Prérequis
* Node.js (v18+)
* Flutter SDK (v3.20.0+)
* PostgreSQL fonctionnel en local ou en ligne
* Clé API Google Gemini (optionnelle, pour le chatbot)

---

### 1. Configuration du Backend

1. Accédez au répertoire backend et installez les dépendances :
   ```bash
   cd backend
   npm install
   ```

2. Créez un fichier `.env` basé sur `.env.example` :
   ```env
   PORT=4000
   DATABASE_URL=postgresql://postgres:postgres@localhost:5432/fasotransport
   DB_SYNCHRONIZE=true
   JWT_ACCESS_SECRET=votre_secret_jwt_access
   JWT_REFRESH_SECRET=votre_secret_jwt_refresh
   JWT_EXPIRES_IN=1d
   JWT_REFRESH_EXPIRES_IN=7d
   GEMINI_API_KEY=votre_cle_gemini_ici
   ```

3. Exécutez le script d'initialisation pour créer les tables et peupler la base de données :
   ```bash
   npm run seed
   ```

4. Lancez le serveur de développement :
   ```bash
   npm run dev
   ```

*L'API sera disponible sur : `http://localhost:4000`*

---

### 2. Configuration du Dashboard Web (Frontend)

1. Accédez au répertoire frontend et installez les dépendances :
   ```bash
   cd ../frontend
   npm install
   ```

2. Configurez les variables d'environnement dans `.env.local` :
   ```env
   NEXT_PUBLIC_API_URL=http://localhost:4000
   ```

3. Lancez le serveur de développement web :
   ```bash
   npm run dev
   ```

*Ouvrez votre navigateur sur : `http://localhost:3000`*

---

### 3. Configuration de l'Application Mobile (Flutter)

1. Accédez au répertoire mobile :
   ```bash
   cd ../mobile
   ```

2. Récupérez les dépendances Flutter :
   ```bash
   flutter pub get
   ```

3. Configurez l'adresse IP du serveur backend dans [config.dart](file:///c:/Users/hyaci/OneDrive/Desktop/FasoTransport-main/mobile/lib/config.dart) si vous testez sur un appareil physique ou un émulateur Android (par défaut : `http://10.0.2.2:4000` pour Android, et `http://127.0.0.1:4000` pour iOS/Web).

4. Lancez l'application :
   ```bash
   flutter run
   ```

---

## 👥 Comptes de Démo (Générés par le Seed)

| Rôle | Adresse Email | Mot de Passe |
| :--- | :--- | :--- |
| **Administrateur Web** | `admin@fasotransport.bf` | `Password123!` |
| **Agent Terrain Mobile** | `agent@fasotransport.bf` | `Password123!` |
| **Agent Terrain Secondaire** | `i.kone@faso.bf` | `Password123!` |
| **Passager Mobile** | `passager@fasotransport.bf` | `Password123!` |

---

## 🔄 Migration MongoDB vers PostgreSQL

Si vous disposez de données existantes stockées dans une base de données MongoDB, vous pouvez les migrer automatiquement vers PostgreSQL à l'aide de notre script :

1. Assurez-vous que votre MongoDB est en cours d'exécution.
2. Ajoutez les variables suivantes dans le `.env` du backend :
   ```env
   MONGO_URI=mongodb://localhost:27017/fasotransport
   DATABASE_URL=postgresql://postgres:postgres@localhost:5432/fasotransport
   ```
3. Exécutez le script :
   ```bash
   npm run migrate:mongo
   ```

---

## 🧪 Tests Automatisés

Pour valider le flux d'authentification sur le backend (création d'un compte, login, rafraîchissement du jeton, déconnexion), lancez :
```bash
cd backend
npm run test:auth:flow
```

