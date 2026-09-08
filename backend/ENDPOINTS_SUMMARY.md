# Smriti Backend API — Quick Reference Summary

> **Base URL:** `http://localhost:5000` | **API Prefix:** `/api`  
> **Auth Header:** `Authorization: Bearer <jwt_token>` *(Dev fallback: auto-patient)*  
> **Response Format:** `{ success: boolean, message: string, data: any, timestamp: string }`

---

## 1. System & Auth

| Method | Endpoint | Auth | Request Body / Params | Description |
| :--- | :--- | :---: | :--- | :--- |
| `GET` | `/health` | No | — | System health status & uptime |
| `POST` | `/api/auth/register` | No | `{ name, email, password, role?, phoneNumber? }` | Register user & get JWT |
| `POST` | `/api/auth/login` | No | `{ email, password }` | Login & get JWT |
| `GET` | `/api/auth/me` | Yes | — | Current authenticated user profile |

---

## 2. Patients & Caregivers

| Method | Endpoint | Auth | Request Body / Params | Description |
| :--- | :--- | :---: | :--- | :--- |
| `GET` | `/api/patients` | Yes | — | List patients (filtered by caregiver if applicable) |
| `POST` | `/api/patients` | Yes | `{ userId, caregiverId?, stageOfDementia?, emergencyContact?, medicalNotes?, preferredLanguage? }` | Create patient profile |
| `GET` | `/api/patients/:id` | Yes | Param: `id` | Get patient details |
| `PUT` | `/api/patients/:id` | Yes | Param: `id`, Body: partial patient fields | Update patient profile |
| `GET` | `/api/caregivers/profile` | Yes | — | Get caregiver profile & assigned patients |
| `PUT` | `/api/caregivers/profile` | Yes | `{ relationToPatient?, ngoAffiliation?, notificationPreferences? }` | Update caregiver settings |

---

## 3. Cognitive Games

| Method | Endpoint | Auth | Request Body / Params | Description |
| :--- | :--- | :---: | :--- | :--- |
| `GET` | `/api/games` | Yes | — | List active cognitive therapy games |
| `POST` | `/api/games/session` | Yes | `{ patientId, gameId, score, durationSeconds, difficulty, metrics: { reactionTimeMs, accuracyPercentage, errorCount } }` | Record game session results |
| `GET` | `/api/games/history/:patientId` | Yes | Param: `patientId` | Get patient game history (newest first) |

*Note: `/api/games/sessions` is an alias for `/api/games/session`.*

---

## 4. Reminders

| Method | Endpoint | Auth | Request Body / Params | Description |
| :--- | :--- | :---: | :--- | :--- |
| `GET` | `/api/reminders/:patientId` | Yes | Param: `patientId` | List reminders sorted by time |
| `POST` | `/api/reminders` | Yes | `{ patientId, title, scheduledTime, type?, repeat?, isVoicePromptEnabled?, voicePromptText? }` | Create scheduled reminder |
| `PATCH` | `/api/reminders/:id/status` | Yes | Param: `id`, Body: `{ status }` (`pending` \| `acknowledged` \| `missed` \| `snoozed`) | Update reminder status |
| `DELETE` | `/api/reminders/:id` | Yes | Param: `id` | Delete a reminder |

*Note: `/api/reminders/patient/:patientId` is an alias for `/:patientId`.*

---

## 5. Progress & Family Memories

| Method | Endpoint | Auth | Request Body / Params | Description |
| :--- | :--- | :---: | :--- | :--- |
| `GET` | `/api/progress/:patientId` | Yes | Param: `patientId` | Cognitive timeline & completed tasks |
| `POST` | `/api/progress` | Yes | `{ patientId, cognitiveScore?, memoryRecallScore?, speechFluencyScore?, completedTasksCount?, missedTasksCount?, notes? }` | Record progress log |
| `GET` | `/api/family/:patientId` | Yes | Param: `patientId` | List patient family memories & photos |
| `POST` | `/api/family` | Yes | `{ patientId, title, description?, mediaUrl?, mediaType?, associatedPeople?, eventDate?, tags?, audioPromptUrl? }` | Add family memory |
| `DELETE` | `/api/family/:id` | Yes | Param: `id` | Delete family memory |

*Note: `/api/family/patient/:id` and `/api/family/memories/:id` are aliases for `/api/family/:id`.*

---

## 6. Analytics, Voice & Offline Sync

| Method | Endpoint | Auth | Request Body / Params | Description |
| :--- | :--- | :---: | :--- | :--- |
| `GET` | `/api/analytics/dashboard/:patientId` | Yes | Param: `patientId` | Stats (sessions, reminders, adherence %, assessments) |
| `POST` | `/api/voice/command` | Yes | `{ audio, language? }` | Speech intent & entity extraction |
| `GET` | `/api/voice/prompt` | Yes | Query: `?text=...&language=...` | Synthesize TTS speech prompt |
| `POST` | `/api/sync/` *(or `/push`)* | Yes | `{ patientId, completedReminders: [{ id, status, acknowledgedAt }], gameSessions: [...] }` | Push offline batch records |
| `GET` | `/api/sync/pull/:patientId` | Yes | Param: `patientId`, Query: `?since=ISO_TIMESTAMP` | Pull incremental updates for cache |

---

## Quick Payload Cheat Sheet

### Register / Login
```json
// POST /api/auth/register
{ "name": "Dr. Ananya", "email": "a@demo.com", "password": "pass", "role": "caregiver" }

// POST /api/auth/login
{ "email": "a@demo.com", "password": "pass" }
```

### Game Session
```json
// POST /api/games/session
{ "patientId": "ID", "gameId": "ID", "score": 85, "durationSeconds": 120, "difficulty": "medium", "metrics": { "accuracyPercentage": 90, "reactionTimeMs": 1200, "errorCount": 2 } }
```

### Reminder
```json
// POST /api/reminders
{ "patientId": "ID", "title": "Donepezil 5mg", "scheduledTime": "2026-09-09T08:00:00Z", "type": "medication", "repeat": "daily" }

// PATCH /api/reminders/:id/status
{ "status": "acknowledged" }
```

### Offline Sync Push
```json
// POST /api/sync/push
{ "patientId": "ID", "completedReminders": [{ "id": "REMINDER_ID", "status": "acknowledged" }], "gameSessions": [...] }
```
