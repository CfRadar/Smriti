# Smriti (स्मृति)

> **BHADWE POORE TIME YAHI DEKHTA REHTA HAI KYA ?
KOI KAAM NHI HAI 


An Intelligent, Culturally-Attuned Cognitive Care and Memory Assistance Ecosystem for Dementia and Alzheimer's Patients, Caregivers, and Clinicians.**

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![React](https://img.shields.io/badge/React-18.3-61DAFB?logo=react&logoColor=black)](https://react.dev)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.5-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![MongoDB](https://img.shields.io/badge/MongoDB-6.0-47A248?logo=mongodb&logoColor=white)](https://www.mongodb.com)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://www.docker.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 📖 Table of Contents

1. [Executive Overview](#-executive-overview)
2. [Clinical & Cultural Foundation](#-clinical--cultural-foundation)
3. [System Architecture & Topology](#-system-architecture--topology)
4. [Ecosystem Subsystems](#-ecosystem-subsystems)
   - [Patient Mobile Application (Flutter)](#1-patient-mobile-application-apps_patient)
   - [Caregiver & Clinical Web Portal (React + Vite)](#2-caregiver--clinical-web-portal-apps_web)
   - [Core REST & Sync Backend (Node.js Express)](#3-core-rest--sync-backend-backend)
   - [Cognitive & Speech AI Microservice (Python FastAPI)](#4-cognitive--speech-ai-microservice-ai)
   - [Shared Contracts & Domain Schemas (Shared)](#5-shared-contracts--constants-shared)
5. [Repository Structure](#-repository-structure)
6. [Tech Stack Matrix](#-tech-stack-matrix)
7. [Getting Started & Local Development](#-getting-started--local-development)
   - [Prerequisites](#prerequisites)
   - [One-Click Docker Compose Setup](#one-click-docker-compose-setup)
   - [Manual Step-by-Step Setup](#manual-step-by-step-setup)
8. [Database Seeding & Test Credentials](#-database-seeding--test-credentials)
9. [API Route Reference](#-api-route-reference)
10. [Offline Resilience & Synchronization](#-offline-resilience--synchronization)
11. [Contributing & Code Guidelines](#-contributing)
12. [License](#-license)

---

## 🌟 Executive Overview

**Smriti (स्मृति)** — derived from the Sanskrit word for *memory* and *recollection* — is an integrated, multi-platform digital healthcare ecosystem engineered specifically for individuals living with Mild Cognitive Impairment (MCI), Alzheimer's disease, and related dementias.

Managing cognitive decline demands a compassionate triad of care:
1. **The Patient:** Requires an intuitive, tactile, sensory-friendly interface that bolsters dignity, assists with daily routines, stimulates neuroplasticity, and connects them with cherished memories.
2. **The Caregiver:** Needs real-time visibility into medication adherence, behavioral anomalies, game engagement, and longitudinal cognitive trends without feeling overwhelmed.
3. **The Clinical / NGO Provider:** Requires standardized assessments, decline velocity indicators, speech acoustic biomarkers, and community-level tracking.

Smriti bridges this continuum by coupling an **accessible mobile companion**, a **collaborative web portal**, a **secure offline-first backend**, and an **inference-driven AI engine**.

---

## 🧠 Clinical & Cultural Foundation

Unlike conventional Western-centric cognitive care tools, Smriti incorporates culturally resonant stimuli and proven neurological therapy modalities:

* **Reminiscence Therapy:** Utilizes curated family photographs, familiar cultural stories, and nostalgic songs to spark episodic memory recall and reduce agitation.
* **Culturally Grounded Cognitive Games:**
  * **Bamboo Dance (Cheraw) Simulation:** Rhythmic timing, sensory anticipation, and bilateral motor coordination rooted in traditional folk rhythms.
  * **Folklore & Oral History Modules:** Interactive narrative choice games (e.g., *King Shanaba*) preserving cognitive executive functions and regional cultural lore.
* **Multilingual Localization (6 Languages):** Native user interface and speech prompting supporting English (`en`), Hindi (`hi`), Assamese (`as`), Bengali (`bn`), Mizo (`lus`), and Manipuri/Meiteilon (`mni`).
* **Speech Biomarker Profiling:** Tracks speech rate (WPM), hesitation pause frequencies, and verbal sentiment during daily interactions to identify early markers of dysphasia or cognitive fatigue.

---

## 🏛️ System Architecture & Topology

```
                              +-------------------------------------------+
                              |              End Users                    |
                              |                                           |
                              |   [Patient Mobile]    [Caregiver Web]     |
                              |   Flutter / Dart      React / TypeScript  |
                              +---------+---------------------+-----------+
                                        |                     |
                                        | HTTPS / WSS         | HTTPS / REST
                                        v                     v
                              +-------------------------------------------+
                              |           Nginx Reverse Proxy             |
                              |           (Port 80 / Port 443)            |
                              +---------+---------------------+-----------+
                                        |                     |
                         /api/          |                     |  /ai/
                         +--------------+                     +-----------+
                         |                                                |
                         v                                                v
             +-----------------------+                        +-----------------------+
             |    Node.js Backend    | <====================> |   Python AI Engine    |
             |    Express REST API   |     Internal HTTP      |   FastAPI Microservice|
             |    (Port 5000)        |                        |   (Port 8000)         |
             +-----------+-----------+                        +-----------+-----------+
                         |                                                |
                         v                                                v
             +-----------------------+                        +-----------------------+
             |   MongoDB Database    |                        |   Pre-Trained ML      |
             |   Users, Patients,    |                        |   Weights & Acoustic  |
             |   Reminders, Sessions |                        |   Feature Extractors  |
             +-----------------------+                        +-----------------------+
```

---

## 📱 Ecosystem Subsystems

### 1. Patient Mobile Application (`apps/patient`)

Built with Flutter, the patient app serves as a tactile, calming, and high-contrast digital companion.

* **Cognitive Ergonomics:** Large touch targets, high-contrast color palettes, minimal cognitive load, and zero cluttered menus.
* **Daily Routines & Voice Reminders:** Audio-visual prompts for medication, hydration, and appointments, read aloud using Text-to-Speech (TTS).
* **Voice Assistant & Speech Recognition:** One-touch voice commands to navigate, listen to stories, or query the schedule.
* **Interactive Stimulation Games:**
  * `bamboo_dance_game.dart`: Rhythm and motor coordination across 6 progressive stages (Familiarisation, Alternation, 4 Directions, Rhythm Pattern, Memory, Cheraw Harmony).
  * `family_memory_game.dart`: Personalized face-name association and relation recall using uploaded family photos.
  * `king_shanaba_game.dart`: Folklore-based decision-making and narrative recall.
  * `pattern_memory_game.dart`: Working memory grid and visual sequence recreation.
  * `picture_recognition_game.dart`: Visual-spatial naming and object categorization.
* **Folklore Reader & Reminiscence Karaoke:**
  * Rich storytelling reader with adjustable font sizes, high-contrast themes, narration read-aloud, and daily streak tracking.
  * Nostalgic karaoke player with lyrics synchronization and mood-boosting classic melodies.
* **In-App Caregiver View:** Secure PIN-protected caregiver login inside the app for quick on-device profile updates and log inspections.

### 2. Caregiver & Clinical Web Portal (`apps/web`)

Built with React 18, Vite, TypeScript, and TailwindCSS, providing dashboards tailored to three distinct roles:

* **Caregiver Portal:**
  * **Dashboard Overview:** Real-time patient activity feed, task completion percentages, and today's schedule.
  * **Reminders Manager:** Add, edit, and categorize medication, hydration, and event alarms with custom audio triggers.
  * **Memories & Photo Vault:** Upload family photos, tag relationships (e.g., "Grandson Rohan"), and attach audio hints for the patient's reminiscence games.
  * **Analytics & Reports:** View weekly cognitive trends, game scores, and task adherence charts.
* **Clinical Admin & Doctor Portal:**
  * Longitudinal assessment tracking (MMSE, MoCA, clinical observation notes).
  * System-wide patient progress metrics and decline velocity alerts.
* **NGO & Community Worker Portal:**
  * Community wellness campaigns, support group management, and volunteer task allocations.

### 3. Core REST & Sync Backend (`backend`)

Built with Node.js, Express (ESM), and MongoDB with Mongoose.

* **JWT Authentication & RBAC:** Granular role enforcement (`patient`, `caregiver`, `admin`, `ngo`).
* **Controllers & Business Logic:**
  * `auth`: User registration, secure login, password hashing via bcrypt, token refresh.
  * `patient` & `caregiver`: Profile mapping, patient-caregiver linking, emergency contact records.
  * `reminder`: Granular scheduling, recurrence rules, completion statuses.
  * `game`: Game catalog, session result logging, cognitive domain scoring.
  * `family`: Memory album management, photo metadata, relations indexing.
  * `progress`: Aggregated daily and weekly cognitive scores.
  * `analytics`: Aggregation pipelines computing decline rates and adherence.
  * `voice`: Voice log intake and transcription routing.
  * `sync`: Offline push/pull synchronization delta handler.

### 4. Cognitive & Speech AI Microservice (`ai`)

Built with Python 3.11+ and FastAPI.

* **Decline Risk Estimation (`/predict/cognitive-decline`):**
  * Multi-factorial scoring synthesizing game scores, adherence rates, and speech hesitations into risk categories (`low`, `moderate`, `high`).
* **Speech Biomarker Analysis (`/speech/analyze`):**
  * Analyzes spoken input for fluency score, hesitation count (`um`, `uh`, pauses), words-per-minute tempo, and sentiment tone.
* **Personalized Recall Synthesis (`/personalization/generate-question`):**
  * Dynamically crafts multi-choice trivia questions based on uploaded family memories and relations (e.g., *"Who is shown in this Diwali photo wearing the yellow kurta?"*).
* **Longitudinal Trend Analytics (`/analysis/cognitive-trends` & `/analysis/behavioral-summary`):**
  * Computes decline velocity score, anomaly detection, stability indices, and clinical recommendations over 30/60/90-day windows.

### 5. Shared Contracts & Constants (`shared`)

* **Cognitive Domains:** `episodic_memory`, `executive_function`, `visuospatial`, `language_fluency`, `processing_speed`.
* **Game Classifications:** `memory_recall`, `pattern_match`, `object_recognition`, `word_association`, `daily_sequencing`.
* **API Schemas:** Shared endpoint constants and payload definitions ensuring zero-drift across client and server tiers.

---

## 📂 Repository Structure

```
smriti/
├── apps/
│   ├── patient/                       # Flutter Mobile Companion
│   │   ├── android/                   # Native Android configuration (Gradle 8.14 / AGP 8.11)
│   │   ├── assets/                    # Images, audio files, icons, and folklore text
│   │   │   ├── audio/                 # Sound effects & nostalgic music
│   │   │   ├── images/                # Stimuli assets (animals, clothing, items, photos)
│   │   │   └── mascot/                # Animated companion avatar
│   │   └── lib/
│   │       ├── controllers/           # Voice command controllers
│   │       ├── games/                 # Bamboo Dance, Family Memory, King Shanaba, etc.
│   │       ├── l10n/                  # 6-language localization dictionaries
│   │       ├── models/                # Patient models & data classes
│   │       ├── screens/               # Folklore, Karaoke, Caregiver Login, Dashboard
│   │       ├── services/              # API clients, TTS, voice, FCM, streaks
│   │       └── main.dart              # App bootstrap & main navigation shell
│   │
│   └── web/                           # React 18 + Vite Web Application
│       ├── src/
│       │   ├── components/            # Reusable UI primitives (Buttons, Cards, Modals)
│       │   ├── layouts/               # Dashboard shells with responsive sidebars
│       │   ├── pages/
│       │   │   ├── admin/             # Doctor & Admin oversight views
│       │   │   ├── auth/              # Login, Registration, Password Reset
│       │   │   ├── caregiver/         # Overview, Analytics, Memories, Reminders
│       │   │   └── ngo/               # Community wellness & outreach programs
│       │   ├── services/              # Axios API clients & endpoints
│       │   └── store/                 # State management & auth tokens
│       └── vite.config.ts
│
├── backend/                           # Node.js + Express Core API
│   ├── src/
│   │   ├── config/                    # MongoDB connection & environment settings
│   │   ├── controllers/               # 10 business logic controllers
│   │   ├── middleware/                # JWT auth, role validation, error handling
│   │   ├── models/                    # Mongoose schemas (User, Patient, Reminder, etc.)
│   │   ├── routes/                    # Express route definitions
│   │   ├── scripts/                   # Database seeders (seed.js, seed_caregiver.js)
│   │   ├── services/                  # Inter-service communication with AI microservice
│   │   └── app.js & server.js         # Express app initialization
│   └── package.json
│
├── ai/                                # Python FastAPI Inference Engine
│   ├── app/
│   │   ├── routes/                    # prediction.py, speech.py, analysis.py, etc.
│   │   ├── services/                  # Cognitive heuristic & biomarker pipelines
│   │   └── main.py                    # FastAPI application & CORS setup
│   ├── requirements.txt               # Python package dependencies
│   └── Dockerfile
│
├── shared/                            # Common contracts & constants
│   ├── api-contracts/                 # API endpoint specifications
│   └── constants/                     # Roles, cognitive domains, game types
│
├── infrastructure/                    # Deployment & Proxy Configurations
│   └── nginx/                         # Reverse proxy routing config
│
├── docs/                              # Comprehensive technical specifications
│   ├── architecture/                  # System topology & network diagrams
│   ├── api/                           # Endpoint contracts & parameter specs
│   ├── database/                      # MongoDB entity-relationship details
│   └── ml/                            # Model architectures & inference logic
│
└── docker-compose.yml                 # Orchestration for multi-container stack
```

---

## 💻 Tech Stack Matrix

| Layer | Technology | Primary Libraries / Packages |
| :--- | :--- | :--- |
| **Mobile Client** | Flutter 3.41+ (Dart 3.11+) | `audioplayers`, `flutter_tts`, `speech_to_text`, `shared_preferences`, `permission_handler` |
| **Web Portal** | React 18, Vite 5, TypeScript 5.5 | `react-router-dom`, `lucide-react`, `tailwindcss`, `clsx`, `tailwind-merge` |
| **Backend API** | Node.js 18+ (ESM), Express 4 | `mongoose`, `jsonwebtoken`, `bcryptjs`, `cors`, `helmet`, `morgan`, `multer` |
| **AI Microservice** | Python 3.11+, FastAPI, Uvicorn | `pydantic`, `numpy`, `scipy`, `requests`, `python-dotenv` |
| **Database** | MongoDB 6.0 | Mongoose ODM with indexing on patient IDs and timestamps |
| **Orchestration** | Docker & Docker Compose | Multi-stage Docker builds, isolated network bridge |

---

## 🛠️ Getting Started & Local Development

### Prerequisites

Ensure the following tools are installed on your host system:
* **Node.js**: v18.0.0 or higher ([Download](https://nodejs.org/))
* **Python**: v3.10+ & optionally [uv](https://docs.astral.sh/uv/) for fast virtualenv management
* **Flutter SDK**: v3.10+ (Tested on v3.41.9) ([Install Flutter](https://docs.flutter.dev/get-started/install))
* **Java JDK**: JDK 17 (Required for Android Gradle builds; Temurin JDK 17 recommended)
* **MongoDB**: Local MongoDB community server or MongoDB Atlas URI
* **Docker & Docker Compose**: (Optional, for containerized run)

---

### One-Click Docker Compose Setup

To spin up the Backend API, AI Microservice, Web Portal, and MongoDB database in a single command:

```bash
# Clone the repository
git clone https://github.com/CfRadar/Smriti.git
cd Smriti

# Start all containerized services
docker-compose up --build
```

Once running, the services will be available at:
* **Web Portal:** [http://localhost:3000](http://localhost:3000)
* **Backend REST API:** [http://localhost:5000](http://localhost:5000)
* **AI Microservice & Interactive Swagger Docs:** [http://localhost:8000/docs](http://localhost:8000/docs)
* **MongoDB:** `localhost:27017`

---

### Manual Step-by-Step Setup

If you prefer to run each service individually on your host machine:

#### 1. Start MongoDB
Ensure MongoDB is running locally on port `27017` or prepare your MongoDB Atlas connection string.

```bash
# Example using Docker for MongoDB only:
docker run -d -p 27017:27017 --name smriti-mongo mongo:6.0
```

#### 2. Backend API Setup
```bash
cd backend

# Install dependencies
npm install

# Configure environment variables
# Create a .env file with:
# PORT=5000
# MONGO_URI=mongodb://localhost:27017/smriti
# JWT_SECRET=your_super_secret_jwt_key
# AI_SERVICE_URL=http://localhost:8000

# Seed test accounts (Caregiver, Patient, Reminders, Memories)
npm run seed:caregiver

# Start backend in development mode
npm run dev
```
*The API will start on `http://localhost:5000`.*

#### 3. AI Cognitive Engine Setup
```bash
cd ai

# Using uv (fastest):
uv venv
# On Windows:
.venv\Scripts\activate
# On Linux/macOS:
source .venv/bin/activate

uv pip install -r requirements.txt

# Or using standard pip:
# python -m venv .venv
# source .venv/bin/activate (or .venv\Scripts\activate)
# pip install -r requirements.txt

# Start FastAPI server
uvicorn app.main:app --reload --port 8000
```
*The AI service will be active at `http://localhost:8000` with Swagger docs at `http://localhost:8000/docs`.*

#### 4. Web Portal Setup
```bash
cd apps/web

# Install dependencies
npm install

# Start Vite dev server
npm run dev
```
*Access the web dashboard at `http://localhost:3000` (or `http://localhost:5173`).*

#### 5. Patient Mobile App Setup (Flutter)
```bash
cd apps/patient

# Fetch Dart dependencies
flutter pub get

# (Windows build tip) If Android Studio bundles Java 25, ensure Flutter uses JDK 17:
flutter config --jdk-dir="<PATH_TO_YOUR_JDK_17>"

# Run on a connected Android device, emulator, or Windows desktop
flutter run

# Build release APK
flutter build apk
```
*The output release APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.*

---

## 🔑 Database Seeding & Test Credentials

The backend includes an automated seeder script that provisions a complete family care environment with realistic medical reminders, family albums, and cognitive score history.

Run the seeder:
```bash
cd backend
npm run seed:caregiver
```

### Pre-Configured Test Accounts

| Role | Email | Password | Details |
| :--- | :--- | :--- | :--- |
| **Caregiver** | `caregiver@smriti.com` | `caregiver123` | Linked to Patient *Ramesh Sharma*, manages reminders & photo vault |
| **Patient** | `patient@smriti.com` | `caregiver123` | Patient profile with pre-loaded game sessions and memories |

---

## 📡 API Route Reference

### Authentication (`/api/auth`)
| Method | Endpoint | Access | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/register` | Public | Register new user (`patient`, `caregiver`, `admin`, `ngo`) |
| `POST` | `/api/auth/login` | Public | Authenticate user & issue JWT bearer token |
| `GET` | `/api/auth/profile` | Authenticated | Retrieve authenticated user profile & role |

### Patient & Caregiver Management (`/api/patients`, `/api/caregivers`)
| Method | Endpoint | Access | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/patients/:id` | Caregiver / Doctor | Fetch patient medical profile, stage, and contacts |
| `PUT` | `/api/patients/:id` | Caregiver / Doctor | Update emergency contacts, stage, or baseline notes |
| `GET` | `/api/caregivers/me/patients` | Caregiver | List all patients associated with the caregiver |
| `POST` | `/api/caregivers/link` | Caregiver | Link a patient using their unique identifier |

### Reminders & Routine Schedule (`/api/reminders`)
| Method | Endpoint | Access | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/reminders/patient/:patientId` | Authenticated | Fetch active reminders for a patient |
| `POST` | `/api/reminders` | Caregiver | Create reminder (medication, hydration, exercise) |
| `PATCH`| `/api/reminders/:id/status` | Patient / Caregiver| Mark reminder as completed, snoozed, or missed |

### Games & Cognitive Scores (`/api/games`, `/api/progress`)
| Method | Endpoint | Access | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/games` | Authenticated | List all active stimulation games & domains |
| `POST` | `/api/games/session` | Authenticated | Submit completed game session score & metrics |
| `GET` | `/api/progress/:patientId` | Caregiver / Doctor | Retrieve aggregated cognitive trends & scores |

### Family Reminiscence Memories (`/api/family`)
| Method | Endpoint | Access | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/family/:patientId` | Authenticated | Retrieve family album photos, tags, and hints |
| `POST` | `/api/family` | Caregiver | Upload new family photo with relationship tags |

### AI Inference Engine (`http://localhost:8000`)
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/predict/cognitive-decline` | Computes risk score, risk level (`low`/`moderate`/`high`), and factors |
| `POST` | `/speech/analyze` | Evaluates audio/transcript for hesitations, speech rate, and clarity |
| `POST` | `/personalization/generate-question` | Generates recall trivia from family album metadata |
| `POST` | `/analysis/cognitive-trends` | Trajectory prediction (`improving`/`stable`/`declining`) and decline velocity |
| `POST` | `/analysis/behavioral-summary` | Detects routine adherence anomalies and behavioral stability |

---

## 🔄 Offline Resilience & Synchronization

Recognizing that patients may often reside in areas with fluctuating internet access, Smriti is designed **offline-first**:

1. **Local State Caching:** The patient mobile application stores game logs, audio files, folklore stories, and reminder triggers locally using on-device cache storage.
2. **Delta Push (`POST /api/sync/push`):** When network connectivity is restored, all offline game sessions, completed reminders, and interaction logs are queued and posted with original timestamps.
3. **Delta Pull (`GET /api/sync/pull`):** Fetches changes made by the caregiver (e.g., updated medication dosages, newly added family pictures) that occurred while the patient device was offline.
4. **Conflict Resolution:** Server timestamps govern authoritative state; reminder completions take precedence to prevent double-alerting.

---

## 🤝 Contributing

Contributions to improve accessibility, add regional language translations, or optimize cognitive assessment algorithms are warmly welcomed.

1. **Fork the repository**
2. **Create your feature branch:**
   ```bash
   git checkout -b feature/accessible-high-contrast-theme
   ```
3. **Commit your changes:**
   ```bash
   git commit -m "feat: enhance high contrast accessibility for folklore reader"
   ```
4. **Push to the branch:**
   ```bash
   git push origin feature/accessible-high-contrast-theme
   ```
5. **Open a Pull Request**

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](file:///d:/Smriti/LICENSE) file for details.  
Copyright © 2026 Smriti Contributors.
