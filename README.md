# Smriti (स्मृति)

> An intelligent, multi-platform cognitive care and memory assistance ecosystem designed for dementia and Alzheimer's patients, their caregivers, healthcare administrators, and NGOs.

---

## 🏛️ Project Architecture

```
smriti/
├── apps/
│   ├── patient/            # Flutter (Dart) mobile application for patients
│   └── web/                # React + Vite + TypeScript web portal (Caregiver, Admin, NGO)
├── backend/                # Node.js + Express (JavaScript) core REST & WebSocket API
├── ai/                     # Python + FastAPI cognitive & speech inference engine
├── shared/                 # Shared API contracts, schemas, and common constants
├── infrastructure/         # Deployment setups, Nginx reverse proxy, and orchestration
└── docs/                   # System architecture, API docs, database schema, ML specs
```

---

## 🚀 Services & Tech Stack

| Service | Technology | Description |
| :--- | :--- | :--- |
| **Patient App** | Flutter (Dart) | Simplified, high-contrast, voice-enabled mobile companion for patients |
| **Web Portal** | React 18 / Vite / TypeScript | Dashboard for Caregivers, Admins, and NGOs |
| **Backend API** | Node.js / Express (ESM JavaScript) | Business logic, authentication, reminders, games, sync engine |
| **AI Engine** | Python / FastAPI / PyTorch / Transformers | Speech analysis, cognitive decline prediction, personalized recall |
| **Infrastructure** | Docker Compose, Nginx | Multi-container development and deployment |

---

## 🛠️ Getting Started

### Prerequisites
- Node.js (v18+) & npm (v9+)
- Python (v3.10+) & [uv](https://docs.astral.sh/uv/)
- Flutter SDK (v3.10+)
- Docker & Docker Compose (Optional for containerized run)

### Running with Docker Compose
```bash
docker-compose up --build
```

### Local Development Setup

#### 1. Backend
```bash
cd backend
npm install
cp .env.example .env
npm run dev
```

#### 2. Web Portal
```bash
cd apps/web
npm install
npm run dev
```

#### 3. AI Service (Python & uv)
```bash
# Create virtual environment with uv
uv venv

# Activate virtual environment
# On Windows:
.venv\Scripts\activate
# On Unix:
source .venv/bin/activate

# Install dependencies using uv
uv pip install -r requirements.txt

# Run the FastAPI server
cd ai
uv run uvicorn app.main:app --reload --port 8000
```

#### 4. Patient App (Flutter)
```bash
cd apps/patient
flutter pub get
flutter run
```

---

## 📄 License
All rights reserved.
