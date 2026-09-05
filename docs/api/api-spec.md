# Smriti (स्मृति) — REST & AI API Specification

## 1. Authentication (`/api/auth`)

### POST `/api/auth/register`
- **Body**: `{ "name": "Dr. Sarah", "email": "sarah@smriti.care", "password": "securepassword", "role": "caregiver" }`
- **Response** `201 Created`: `{ "success": true, "token": "<JWT_TOKEN>", "user": { "id": "...", "name": "...", "email": "...", "role": "..." } }`

### POST `/api/auth/login`
- **Body**: `{ "email": "sarah@smriti.care", "password": "securepassword" }`
- **Response** `200 OK`: `{ "success": true, "token": "<JWT_TOKEN>", "user": { ... } }`

### GET `/api/auth/me`
- **Headers**: `Authorization: Bearer <TOKEN>`
- **Response** `200 OK`: `{ "success": true, "data": { ... } }`

---

## 2. Patients (`/api/patients`)

### GET `/api/patients`
- **Headers**: `Authorization: Bearer <TOKEN>`
- **Response** `200 OK`: Array of patient profiles accessible by the authenticated user.

### POST `/api/patients`
- **Body**: `{ "name": "Ramesh Gupta", "age": 72, "diagnosis": "Early Stage Dementia", "emergencyContact": "+91-9876543210" }`
- **Response** `201 Created`: Created patient document.

### GET `/api/patients/:id`
- **Response** `200 OK`: Single patient details including assigned caregiver and clinical markers.

---

## 3. Cognitive Games (`/api/games`)

### GET `/api/games`
- **Response** `200 OK`: Available games (Memory Recall, Pattern Matching, Word Association).

### POST `/api/games/session`
- **Body**: `{ "patientId": "...", "gameId": "...", "score": 85.0, "timeTakenSeconds": 140, "mistakesCount": 2, "domain": "episodic_memory" }`
- **Response** `201 Created`: Saved session with performance analytics.

---

## 4. Reminders (`/api/reminders`)

### GET `/api/reminders/:patientId`
- **Response** `200 OK`: Active reminders (medication, hydration, family video call, meals).

### POST `/api/reminders`
- **Body**: `{ "patientId": "...", "title": "Blood Pressure Medication", "time": "08:30", "type": "medication", "repeat": "daily" }`
- **Response** `201 Created`: Created reminder record.

### PATCH `/api/reminders/:id/status`
- **Body**: `{ "status": "completed" }` (or `"missed"`)
- **Response** `200 OK`: Updated reminder state.

---

## 5. Offline Sync Engine (`/api/sync`)

### POST `/api/sync/push`
- **Body**: `{ "patientId": "...", "pendingSessions": [...], "pendingReminders": [...], "timestamp": "2026-09-05T12:00:00Z" }`
- **Response** `200 OK`: Number of synced events acknowledged by server.

### GET `/api/sync/pull/:patientId`
- **Query**: `?since=2026-09-04T00:00:00Z`
- **Response** `200 OK`: Delta changes for memories, games, and reminders since given timestamp.

---

## 6. AI Microservice Endpoints (Port 8000 / `/ai/`)

### POST `/predict/cognitive-decline`
- **Body**:
  ```json
  {
    "patient_id": "P001",
    "age": 72,
    "game_scores": [82.0, 79.5, 84.0],
    "task_completion_rate": 0.88,
    "speech_hesitations_per_min": 3.8
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "risk_score": 0.22,
    "risk_category": "low",
    "progression_rate": "stable",
    "key_factors": ["Game performance stability", "Daily task adherence"],
    "confidence": 0.89
  }
  ```

### POST `/speech/analyze`
- **Body**: `{ "transcript": "I had breakfast with tea and bread this morning.", "metadata": {} }`
- **Response** `200 OK`:
  ```json
  {
    "fluency_score": 93.2,
    "hesitation_count": 0,
    "speech_rate_wpm": 128,
    "sentiment": "positive",
    "acoustic_clarity": 0.90
  }
  ```

### POST `/personalization/generate-question`
- **Body**: `{ "patient_id": "P001", "memories": [...], "difficulty": "easy" }`
- **Response** `200 OK`: Generates targeted recall question with family context and hint.

### POST `/analysis/cognitive-trends`
- **Body**: `{ "patient_id": "P001", "timeframe_days": 30, "session_scores": [85, 82, 80] }`
- **Response** `200 OK`: Trend trajectory (`improving`, `stable`, `declining`) and clinical observations.
