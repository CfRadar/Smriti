# Smriti Backend API Endpoints Documentation

This document provides a comprehensive and detailed reference for all REST API endpoints currently implemented in the `smriti-backend` service.

---

## Overview & Architecture

- **Base URL:** `http://localhost:5000` (configurable via `PORT` environment variable)
- **API Prefix:** `/api` (with the exception of `/health`)
- **Format:** JSON (`Content-Type: application/json`)
- **CORS:** Enabled for cross-origin consumer clients (React Web Portal & Flutter Mobile App)
- **Security:** Protected with [Helmet](https://helmetjs.github.io/) HTTP security headers

---

## Authentication & Authorization

Protected endpoints require a JSON Web Token (JWT) in the `Authorization` header:

```http
Authorization: Bearer <jwt_token>
```

### Dev Mode Fallback
In non-production environments (`NODE_ENV !== 'production'`), if the `Authorization` header is omitted, the authentication middleware automatically injects a default mock patient context for kiosk/testing ease:
```json
{
  "id": "6aa03d2f5acb6949838f2780",
  "role": "patient"
}
```

---

## Standard Response Envelope

All API endpoints follow a standardized response envelope format.

### Success Response (`2xx`)
```json
{
  "success": true,
  "message": "Operation description message",
  "data": { ... },
  "timestamp": "2026-09-09T01:00:00.000Z"
}
```

### Error Response (`4xx` / `5xx`)
```json
{
  "success": false,
  "message": "Error description message",
  "errors": null,
  "timestamp": "2026-09-09T01:00:00.000Z"
}
```

---

## Quick Reference Table

| Category | Method | Endpoint Path | Auth Required | Description |
| :--- | :--- | :--- | :---: | :--- |
| **System** | `GET` | `/health` | No | System health and uptime |
| **Auth** | `POST` | `/api/auth/register` | No | Register new user account |
| **Auth** | `POST` | `/api/auth/login` | No | Authenticate user & get JWT |
| **Auth** | `GET` | `/api/auth/me` | Yes | Get currently authenticated user profile |
| **Patients** | `GET` | `/api/patients` | Yes | List patients (filtered by caregiver if applicable) |
| **Patients** | `POST` | `/api/patients` | Yes | Create a new patient profile |
| **Patients** | `GET` | `/api/patients/:id` | Yes | Retrieve single patient details |
| **Patients** | `PUT` | `/api/patients/:id` | Yes | Update an existing patient profile |
| **Caregivers** | `GET` | `/api/caregivers/profile` | Yes | Get caregiver profile and assigned patients |
| **Caregivers** | `PUT` | `/api/caregivers/profile` | Yes | Update caregiver settings and preferences |
| **Games** | `GET` | `/api/games` | Yes | List active cognitive therapy games |
| **Games** | `POST` | `/api/games/session` or `/sessions` | Yes | Record completed cognitive game session |
| **Games** | `GET` | `/api/games/history/:patientId` | Yes | Retrieve game session history for a patient |
| **Reminders** | `GET` | `/api/reminders/:patientId` | Yes | Get all scheduled reminders for a patient |
| **Reminders** | `POST` | `/api/reminders` | Yes | Create a new reminder |
| **Reminders** | `PATCH`| `/api/reminders/:id/status` | Yes | Update reminder status (pending, acknowledged, etc.) |
| **Reminders** | `DELETE`| `/api/reminders/:id` | Yes | Delete a reminder |
| **Progress** | `GET` | `/api/progress/:patientId` | Yes | Get patient cognitive and task progress timeline |
| **Progress** | `POST` | `/api/progress` | Yes | Record a progress entry |
| **Family** | `GET` | `/api/family/:patientId` | Yes | List family memories and photos for patient |
| **Family** | `POST` | `/api/family` | Yes | Add a new family memory entry |
| **Family** | `DELETE`| `/api/family/:id` | Yes | Delete a family memory entry |
| **Analytics** | `GET` | `/api/analytics/dashboard/:patientId` | Yes | Aggregate dashboard metrics and adherence rates |
| **Voice** | `POST` | `/api/voice/command` | Yes | Process voice command and extract intent/entities |
| **Voice** | `GET` | `/api/voice/prompt` | Yes | Synthesize speech prompt audio |
| **Sync** | `POST` | `/api/sync/` or `/api/sync/push` | Yes | Push offline completions (reminders, games) |
| **Sync** | `GET` | `/api/sync/pull/:patientId` | Yes | Pull latest updates for offline caching |

---

## Detailed Endpoint Specifications

### 1. System & Health

#### `GET /health`
Returns the operational health and uptime of the backend service.

- **Access:** Public
- **Headers:** None required
- **Response `200 OK`:**
  ```json
  {
    "status": "ok",
    "service": "smriti-backend",
    "uptime": 124.58
  }
  ```

---

### 2. Authentication (`/api/auth`)

#### `POST /api/auth/register`
Registers a new user account (Caregiver, Patient, NGO, Admin) and returns a signed JWT.

- **Access:** Public
- **Request Body:**
  ```json
  {
    "name": "Ananya Sharma",
    "email": "ananya@example.com",
    "password": "StrongPassword123!",
    "role": "caregiver",
    "phoneNumber": "+919876543210"
  }
  ```
  - `role` *(optional)*: `'patient' | 'caregiver' | 'admin' | 'ngo'` (default: `'caregiver'`)
- **Response `201 Created`:**
  ```json
  {
    "success": true,
    "message": "User registered successfully",
    "data": {
      "user": {
        "id": "66d01234567890abcdef1234",
        "name": "Ananya Sharma",
        "email": "ananya@example.com",
        "role": "caregiver"
      },
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    },
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```
- **Error Responses:**
  - `400 Bad Request`: When email already exists or validation fails.

---

#### `POST /api/auth/login`
Authenticates user credentials and issues a JWT token.

- **Access:** Public
- **Request Body:**
  ```json
  {
    "email": "ananya@example.com",
    "password": "StrongPassword123!"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Login successful",
    "data": {
      "user": {
        "id": "66d01234567890abcdef1234",
        "name": "Ananya Sharma",
        "email": "ananya@example.com",
        "role": "caregiver"
      },
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    },
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```
- **Error Responses:**
  - `401 Unauthorized`: Invalid email or password.

---

#### `GET /api/auth/me`
Retrieves token payload details for the currently active session.

- **Access:** Authenticated (Bearer Token)
- **Headers:** `Authorization: Bearer <token>`
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Current user profile",
    "data": {
      "user": {
        "id": "66d01234567890abcdef1234",
        "role": "caregiver",
        "email": "ananya@example.com"
      }
    },
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```

---

### 3. Patient Management (`/api/patients`)

#### `GET /api/patients`
Retrieves accessible patients. If the authenticated user is a caregiver, this endpoint automatically scopes results to only patients linked in the caregiver's `assignedPatients` array.

- **Access:** Authenticated
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Patients retrieved",
    "data": [
      {
        "_id": "66d03d2f5acb6949838f2781",
        "userId": {
          "_id": "66d01234567890abcdef1235",
          "name": "Ramesh Sen",
          "email": "ramesh@example.com",
          "phoneNumber": "+919123456780",
          "profileImage": "https://example.com/avatar.jpg"
        },
        "caregiverId": "66d011115acb6949838f2700",
        "dateOfBirth": "1954-04-12T00:00:00.000Z",
        "gender": "male",
        "stageOfDementia": "mild_cognitive_impairment",
        "emergencyContact": {
          "name": "Ananya Sharma",
          "relation": "Daughter",
          "phone": "+919876543210"
        },
        "medicalNotes": "Prescribed Donepezil 5mg daily. Prefers morning walks.",
        "preferredLanguage": "bn",
        "createdAt": "2026-09-01T10:00:00.000Z",
        "updatedAt": "2026-09-08T12:00:00.000Z"
      }
    ],
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```

---

#### `POST /api/patients`
Creates a new patient profile.

- **Access:** Authenticated
- **Request Body:**
  ```json
  {
    "userId": "66d01234567890abcdef1235",
    "caregiverId": "66d011115acb6949838f2700",
    "dateOfBirth": "1954-04-12",
    "gender": "male",
    "stageOfDementia": "mild_cognitive_impairment",
    "emergencyContact": {
      "name": "Ananya Sharma",
      "relation": "Daughter",
      "phone": "+919876543210"
    },
    "medicalNotes": "Mild short term memory loss.",
    "preferredLanguage": "bn"
  }
  ```
  - `stageOfDementia` enum: `'mild_cognitive_impairment' | 'early_stage' | 'middle_stage' | 'late_stage'`
  - `gender` enum: `'male' | 'female' | 'other'`
- **Response `201 Created`:** Created patient record object.

---

#### `GET /api/patients/:id`
Fetches a single patient profile by their MongoDB ObjectId, populating user details and caregiver reference.

- **Access:** Authenticated
- **Path Parameter:** `id` - Patient ObjectId
- **Response `200 OK`:** Single patient document.
- **Error Responses:** `404 Not Found` if patient does not exist.

---

#### `PUT /api/patients/:id`
Updates demographic or medical profile fields for a patient.

- **Access:** Authenticated
- **Path Parameter:** `id` - Patient ObjectId
- **Request Body:** Any partial fields from the patient schema.
- **Response `200 OK`:** Updated patient document.

---

### 4. Caregiver Profile (`/api/caregivers`)

#### `GET /api/caregivers/profile`
Retrieves the profile of the currently authenticated caregiver, with `assignedPatients` populated.

- **Access:** Authenticated
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Caregiver profile",
    "data": {
      "_id": "66d011115acb6949838f2700",
      "userId": "66d01234567890abcdef1234",
      "assignedPatients": [
        {
          "_id": "66d03d2f5acb6949838f2781",
          "stageOfDementia": "mild_cognitive_impairment"
        }
      ],
      "relationToPatient": "Daughter",
      "ngoAffiliation": "SilverAge Foundation",
      "notificationPreferences": {
        "sms": true,
        "email": true,
        "push": true
      }
    },
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```

---

#### `PUT /api/caregivers/profile`
Updates relation, NGO affiliation, or notification settings for the authenticated caregiver.

- **Access:** Authenticated
- **Request Body:**
  ```json
  {
    "relationToPatient": "Primary Caregiver / Daughter",
    "notificationPreferences": {
      "sms": false,
      "email": true,
      "push": true
    }
  }
  ```
- **Response `200 OK`:** Updated caregiver object.

---

### 5. Cognitive Therapy Games (`/api/games`)

#### `GET /api/games`
Lists all active cognitive exercises and cultural games configured in the system (e.g., King Shanaba, Memory Match, Pattern Recall).

- **Access:** Authenticated
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Available cognitive games",
    "data": [
      {
        "_id": "66d077775acb6949838f2799",
        "title": "King Shanaba (Kang Court)",
        "description": "Traditional Northeast Manipuri target sliding and memory game",
        "type": "pattern_recall",
        "difficultyLevels": ["easy", "medium", "hard"],
        "config": {
          "boardType": "kang_court",
          "targetCount": 7
        },
        "isActive": true
      }
    ],
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```

---

#### `POST /api/games/session` *(alias: `/api/games/sessions`)*
Submits metrics and completion stats after a patient completes a game session.

- **Access:** Authenticated
- **Request Body:**
  ```json
  {
    "patientId": "66d03d2f5acb6949838f2781",
    "gameId": "66d077775acb6949838f2799",
    "score": 85,
    "durationSeconds": 140,
    "difficulty": "medium",
    "metrics": {
      "reactionTimeMs": 1250,
      "accuracyPercentage": 92,
      "errorCount": 2
    },
    "completedAt": "2026-09-09T00:55:00.000Z"
  }
  ```
- **Response `201 Created`:** Created `GameSession` document.

---

#### `GET /api/games/history/:patientId`
Fetches a patient's historical game play sessions sorted in reverse chronological order (`completedAt: -1`), with game definitions populated.

- **Access:** Authenticated
- **Path Parameter:** `patientId` - Patient ObjectId
- **Response `200 OK`:** Array of game session logs.

---

### 6. Reminders & Alerts (`/api/reminders`)

#### `GET /api/reminders/:patientId` *(alias: `/api/reminders/patient/:patientId`)*
Retrieves all reminders for a specific patient, sorted chronologically by `scheduledTime: 1`.

- **Access:** Authenticated
- **Path Parameter:** `patientId` - Patient ObjectId
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Reminders list",
    "data": [
      {
        "_id": "66d088885acb6949838f2801",
        "patientId": "66d03d2f5acb6949838f2781",
        "caregiverId": "66d011115acb6949838f2700",
        "title": "Morning Donepezil Tablet",
        "description": "Take 1 tablet with water after breakfast",
        "type": "medication",
        "scheduledTime": "2026-09-09T08:30:00.000Z",
        "repeat": "daily",
        "isVoicePromptEnabled": true,
        "voicePromptText": "Dadu, it is time for your morning tablet.",
        "status": "pending"
      }
    ],
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```

---

#### `POST /api/reminders`
Schedules a new reminder for medication, hydration, meals, or activities.

- **Access:** Authenticated
- **Request Body:**
  ```json
  {
    "patientId": "66d03d2f5acb6949838f2781",
    "caregiverId": "66d011115acb6949838f2700",
    "title": "Afternoon Hydration",
    "description": "Drink 1 glass of warm water or juice",
    "type": "hydration",
    "scheduledTime": "2026-09-09T14:00:00.000Z",
    "repeat": "daily",
    "isVoicePromptEnabled": true,
    "voicePromptText": "Time for a glass of water."
  }
  ```
  - `type` enum: `'medication' | 'meal' | 'hydration' | 'activity' | 'appointment' | 'custom'`
  - `repeat` enum: `'none' | 'daily' | 'weekly' | 'custom'`
- **Response `201 Created`:** Created reminder object.

---

#### `PATCH /api/reminders/:id/status`
Updates the acknowledgment status of a reminder (e.g., when marked taken on patient tablet or web dashboard).

- **Access:** Authenticated
- **Path Parameter:** `id` - Reminder ObjectId
- **Request Body:**
  ```json
  {
    "status": "acknowledged"
  }
  ```
  - `status` enum: `'pending' | 'acknowledged' | 'missed' | 'snoozed'`
- **Response `200 OK`:** Updated reminder object.

---

#### `DELETE /api/reminders/:id`
Deletes a scheduled reminder.

- **Access:** Authenticated
- **Path Parameter:** `id` - Reminder ObjectId
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Reminder deleted",
    "data": null,
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```

---

### 7. Progress & Cognitive Timeline (`/api/progress`)

#### `GET /api/progress/:patientId` *(alias: `/api/progress/patient/:patientId`)*
Fetches daily cognitive timeline evaluations and task completion tracking for a patient, ordered by `date: 1`.

- **Access:** Authenticated
- **Path Parameter:** `patientId` - Patient ObjectId
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Patient progress timeline",
    "data": [
      {
        "_id": "66d099995acb6949838f2850",
        "patientId": "66d03d2f5acb6949838f2781",
        "date": "2026-09-08T00:00:00.000Z",
        "cognitiveScore": 78,
        "memoryRecallScore": 82,
        "speechFluencyScore": 75,
        "completedTasksCount": 5,
        "missedTasksCount": 1,
        "notes": "Good engagement with Kang game and recalled grandchildren names."
      }
    ],
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```

---

#### `POST /api/progress`
Records a cognitive score progress entry.

- **Access:** Authenticated
- **Request Body:**
  ```json
  {
    "patientId": "66d03d2f5acb6949838f2781",
    "cognitiveScore": 80,
    "memoryRecallScore": 85,
    "speechFluencyScore": 78,
    "completedTasksCount": 6,
    "missedTasksCount": 0,
    "notes": "Responsive throughout the afternoon."
  }
  ```
- **Response `201 Created`:** Created progress record.

---

### 8. Family Memories & Photo Album (`/api/family`)

#### `GET /api/family/:patientId` *(aliases: `/patient/:patientId`, `/memories/:patientId`)*
Retrieves all family photos, audio prompts, and memory cues tagged for the patient.

- **Access:** Authenticated
- **Path Parameter:** `patientId` - Patient ObjectId
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Family memories retrieved",
    "data": [
      {
        "_id": "66d0aaaa5acb6949838f2900",
        "patientId": "66d03d2f5acb6949838f2781",
        "title": "Family Trip to Shillong Peak",
        "description": "Standing near the viewpoint with grandchildren in winter 2018.",
        "mediaUrl": "https://example.com/photos/shillong.jpg",
        "mediaType": "image",
        "associatedPeople": [
          { "name": "Rahul", "relation": "Grandson" },
          { "name": "Meera", "relation": "Granddaughter" }
        ],
        "eventDate": "2018-12-15T00:00:00.000Z",
        "tags": ["vacation", "hills", "family"],
        "audioPromptUrl": "https://example.com/audio/shillong_prompt.mp3"
      }
    ],
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```

---

#### `POST /api/family`
Adds a memory item with media URL, relationships, and optional audio prompt.

- **Access:** Authenticated
- **Request Body:**
  ```json
  {
    "patientId": "66d03d2f5acb6949838f2781",
    "title": "Trip to Loktak Lake",
    "description": "Boating along the phumdis in Manipur.",
    "mediaUrl": "https://example.com/photos/loktak.jpg",
    "mediaType": "image",
    "associatedPeople": [
      { "name": "Ananya", "relation": "Daughter" }
    ],
    "eventDate": "2020-02-10T00:00:00.000Z",
    "tags": ["lake", "manipur", "boating"],
    "audioPromptUrl": "https://example.com/audio/loktak.mp3"
  }
  ```
  - `mediaType` enum: `'image' | 'audio' | 'video'` (default: `'image'`)
- **Response `201 Created`:** Created memory item.

---

#### `DELETE /api/family/:id`
Removes a memory entry.

- **Access:** Authenticated
- **Path Parameter:** `id` - Memory ObjectId
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Memory removed",
    "data": null,
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```

---

### 9. Analytics & Summary Dashboard (`/api/analytics`)

#### `GET /api/analytics/dashboard/:patientId`
Calculates aggregated clinical statistics for caregiver and admin dashboards, including session totals, pending vs acknowledged reminders, recent assessments, and computed medication/routine adherence percentage.

- **Access:** Authenticated
- **Path Parameter:** `patientId` - Patient ObjectId
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Analytics summary",
    "data": {
      "totalSessions": 18,
      "totalReminders": 34,
      "pendingReminders": 4,
      "acknowledgedReminders": 30,
      "recentAssessments": [
        {
          "_id": "66d0bbbb5acb6949838f2920",
          "patientId": "66d03d2f5acb6949838f2781",
          "assessmentType": "DAILY_COGNITIVE_CHECK",
          "overallScore": 84,
          "riskLevel": "low",
          "createdAt": "2026-09-08T18:00:00.000Z"
        }
      ],
      "adherenceRate": 88
    },
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```

---

### 10. Voice & Speech Processing (`/api/voice`)

#### `POST /api/voice/command`
Processes voice recordings from the patient kiosk/mobile app, executes intent extraction, and returns structured command entities.

- **Access:** Authenticated
- **Request Body:**
  ```json
  {
    "audio": "base64_encoded_audio_string_or_pcm",
    "language": "en"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Voice command processed",
    "data": {
      "transcription": "Take medicine for blood pressure at 2 PM",
      "intent": "create_reminder",
      "extractedEntities": {
        "action": "take_medicine",
        "item": "blood pressure medication",
        "time": "14:00"
      },
      "confidence": 0.94
    },
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```

---

#### `GET /api/voice/prompt`
Synthesizes speech audio for patient reminders or voice-guided navigation.

- **Access:** Authenticated
- **Query Parameters:**
  - `text` *(string, required)*: Text to synthesize
  - `language` *(string, optional)*: Language code (default: `'en'`)
- **Example Request:** `GET /api/voice/prompt?text=Time%20to%20take%20medicine&language=en`
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Prompt synthesized",
    "data": {
      "audioUrl": "/static/prompts/prompt_1725843600000.mp3",
      "durationSeconds": 3.5,
      "text": "Time to take medicine"
    },
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```

---

### 11. Offline Sync Engine (`/api/sync`)

#### `POST /api/sync` *(alias: `/api/sync/push`)*
Pushes offline actions recorded on patient devices (e.g. tablet used with intermittent internet connectivity), including completed reminders and game session metrics.

- **Access:** Authenticated
- **Request Body:**
  ```json
  {
    "patientId": "66d03d2f5acb6949838f2781",
    "completedReminders": [
      {
        "id": "66d088885acb6949838f2801",
        "status": "acknowledged",
        "acknowledgedAt": "2026-09-09T00:45:00.000Z"
      }
    ],
    "gameSessions": [
      {
        "gameId": "66d077775acb6949838f2799",
        "score": 90,
        "durationSeconds": 110,
        "difficulty": "easy",
        "metrics": {
          "reactionTimeMs": 1100,
          "accuracyPercentage": 95,
          "errorCount": 1
        },
        "completedAt": "2026-09-09T00:50:00.000Z"
      }
    ],
    "timestamp": "2026-09-09T00:52:00.000Z"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Data synchronization complete",
    "data": {
      "success": true,
      "serverTimestamp": "2026-09-09T01:00:00.000Z",
      "results": {
        "syncedReminders": 1,
        "syncedGames": 1
      }
    },
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```

---

#### `GET /api/sync/pull/:patientId`
Retrieves latest reminders and family memories for offline caching on patient devices.

- **Access:** Authenticated
- **Path Parameter:** `patientId` - Patient ObjectId
- **Query Parameter:**
  - `since` *(optional, ISO 8601 string)*: Filter to records updated on or after this timestamp.
- **Example Request:** `GET /api/sync/pull/66d03d2f5acb6949838f2781?since=2026-09-08T00:00:00.000Z`
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Latest updates retrieved for offline cache",
    "data": {
      "patientId": "66d03d2f5acb6949838f2781",
      "serverTimestamp": "2026-09-09T01:00:00.000Z",
      "reminders": [ ... ],
      "memories": [ ... ]
    },
    "timestamp": "2026-09-09T01:00:00.000Z"
  }
  ```

---

## Status Codes Summary

| Code | Label | Meaning |
| :---: | :--- | :--- |
| `200` | **OK** | Request succeeded and data returned |
| `201` | **Created** | New resource successfully created |
| `400` | **Bad Request** | Missing required parameters or failed validation |
| `401` | **Unauthorized** | Missing, invalid, or expired JWT bearer token |
| `404` | **Not Found** | Targeted entity does not exist |
| `500` | **Internal Server Error**| Unhandled exception or database error |
