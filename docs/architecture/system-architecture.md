# Smriti (स्मृति) — System Architecture

## 1. Executive Overview
Smriti is an integrated, multi-platform cognitive assistance and healthcare monitoring ecosystem designed for patients living with dementia and Alzheimer's, their caregivers, clinical administrators, and non-governmental organizations (NGOs).

## 2. Core Architecture Topology

```
                   +---------------------------------------+
                   |           Clients / Users             |
                   |                                       |
                   |  [Flutter App]     [React Web Portal] |
                   |  (Patients)        (Caregiver/Admin)  |
                   +-------+--------------------+----------+
                           |                    |
                           v                    v
                   +---------------------------------------+
                   |         Nginx Reverse Proxy           |
                   |            (Port 80/443)              |
                   +-------+--------------------+----------+
                           |                    |
             /api/         |                    |  /ai/
             +-------------+                    +----------+
             |                                             |
             v                                             v
+------------------------+                     +------------------------+
|   Node.js Backend      | <=================> |    Python AI Engine    |
|   Express REST API     |   Internal HTTP     |    FastAPI Microservice|
|   (Port 5000)          |                     |    (Port 8000)         |
+-----------+------------+                     +-----------+------------+
            |                                              |
            v                                              v
+------------------------+                     +------------------------+
|   MongoDB Database     |                     |     Model Weights      |
|   Users, Patients,     |                     |     & Acoustic Models  |
|   Reminders, Games     |                     +------------------------+
+------------------------+
```

## 3. Subsystem Breakdown

### 3.1 Patient Mobile Application (`apps/patient`)
- **Technology**: Flutter (Dart) with Material 3.
- **Design Philosophy**: High contrast, large tactile touch targets, voice-prompted reminders, and simplified cognitive navigation.
- **Features**:
  - Daily audio/visual reminders for medication, hydration, and appointments.
  - Interactive reminiscence therapy via family photo galleries.
  - Daily cognitive stimulation games (memory match, visual puzzles, sequencing).
  - One-touch voice interaction with intelligent fallback speech recognition.
  - Offline-first caching with bi-directional sync engine.

### 3.2 Caregiver & Admin Web Portal (`apps/web`)
- **Technology**: React 18 / 19, Vite, TypeScript, and responsive CSS.
- **Roles & Portals**:
  - **Caregiver Portal**: Patient health tracking, personalized memory photo uploads, reminder configuration, and emergency contact management.
  - **Clinical Admin**: Cognitive decline trajectory analytics, neuropsychological assessment submissions, and system user management.
  - **NGO Portal**: Community-level cognitive wellness programs, support group coordination, and volunteer task allocation.

### 3.3 Core Backend API (`backend`)
- **Technology**: Node.js (ESM JavaScript), Express, Mongoose.
- **Responsibilities**:
  - JWT-based authentication and role-based access control (`auth.middleware.js`, `role.middleware.js`).
  - 10 functional controllers covering Auth, Patients, Caregivers, Games, Reminders, Progress, Family Memories, Analytics, Voice, and Sync.
  - Synchronization engine resolving offline timestamps and mobile data deltas.
  - Inter-service orchestration with the AI cognitive microservice.

### 3.4 AI Cognitive & Speech Engine (`ai`)
- **Technology**: Python 3.11+, FastAPI, Uvicorn, Pydantic, PyTorch/Transformers compatible.
- **Responsibilities**:
  - **Cognitive Risk Prediction**: Multi-factorial risk scoring combining longitudinal game performance, task adherence, and clinical baselines.
  - **Speech Biomarker Analysis**: Extraction of verbal hesitation markers, speech tempo (words per minute), acoustic clarity, and sentiment.
  - **Personalized Reminiscence Generator**: Dynamic synthesis of recall questions from family album metadata and relations.
  - **Longitudinal Trend Analytics**: Multi-week decline velocity computation and anomaly alerts.

## 4. Security, Privacy & Offline Resilience
- **Data Protection**: Sensitive patient health information is isolated with strict RBAC boundaries.
- **Offline Protocol**: Mobile client maintains a local SQLite/Hive database queue; when connectivity is restored, `/sync/push` submits pending logs and `/sync/pull` updates server changes.
