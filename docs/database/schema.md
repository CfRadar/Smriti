# Smriti (स्मृति) — Database Schema & Data Models

The persistence layer uses MongoDB managed through Mongoose models in `backend/src/models/`.

## 1. Entity-Relationship Overview

```
 [User] <───────── (1:1) ─────────> [Caregiver]
   │                                    │
   │ (1:N)                              │ (1:N)
   ▼                                    ▼
[Patient] ────────────────────────> [FamilyMemory]
   │
   ├─────── (1:N) ───────> [Reminder]
   ├─────── (1:N) ───────> [GameSession]
   ├─────── (1:N) ───────> [Progress]
   └─────── (1:N) ───────> [Assessment]
```

## 2. Core Collections

### 2.1 Users (`User.js`)
- `_id`: ObjectId
- `name`: String, required
- `email`: String, unique, indexed
- `password`: String (bcrypt hashed)
- `role`: Enum (`"patient"`, `"caregiver"`, `"admin"`, `"ngo"`)
- `phone`: String
- `createdAt`, `updatedAt`: Timestamps

### 2.2 Patients (`Patient.js`)
- `_id`: ObjectId
- `userId`: ObjectId (optional reference to User if patient logs in)
- `caregiverId`: ObjectId (ref: User)
- `name`: String, required
- `age`: Number
- `stage`: Enum (`"early"`, `"moderate"`, `"severe"`)
- `emergencyContact`: String
- `baselineMMSE`: Number (Mini-Mental State Exam score)
- `medicalNotes`: String
- `createdAt`, `updatedAt`: Timestamps

### 2.3 Caregivers (`Caregiver.js`)
- `_id`: ObjectId
- `userId`: ObjectId (ref: User, required, unique)
- `assignedPatients`: [ObjectId (ref: Patient)]
- `relationship`: String (e.g. "Daughter", "Nurse")
- `notificationPreferences`: Object (`{ email: Boolean, sms: Boolean, push: Boolean }`)

### 2.4 Games (`Game.js`) & GameSessions (`GameSession.js`)
- **Game**: `title`, `slug`, `domain` (e.g., `episodic_memory`), `difficultyLevels`, `description`
- **GameSession**:
  - `patientId`: ObjectId (ref: Patient, indexed)
  - `gameId`: ObjectId (ref: Game)
  - `score`: Number (0 - 100)
  - `timeTakenSeconds`: Number
  - `mistakesCount`: Number
  - `domain`: String
  - `completedAt`: Date

### 2.5 Reminders (`Reminder.js`)
- `patientId`: ObjectId (ref: Patient, indexed)
- `title`: String
- `time`: String (e.g. "09:00 AM")
- `type`: Enum (`"medication"`, `"hydration"`, `"meal"`, `"activity"`, `"custom"`)
- `frequency`: Enum (`"once"`, `"daily"`, `"weekly"`)
- `status`: Enum (`"pending"`, `"completed"`, `"missed"`)
- `scheduledDate`: Date

### 2.6 Family Memories (`FamilyMemory.js`)
- `patientId`: ObjectId (ref: Patient, indexed)
- `mediaUrl`: String (S3 / Cloud Storage / Static image URI)
- `title`: String
- `description`: String
- `eventDate`: String
- `peopleTagged`: [String] (e.g. `["Grandson Rohan", "Son Vikram"]`)
- `relationshipNotes`: String
- `audioNoteUrl`: String (optional voice prompt recording)

### 2.7 Progress & Assessments (`Progress.js`, `Assessment.js`)
- **Progress**: Aggregated monthly and weekly cognitive scores, task completion rates, and AI-derived velocity.
- **Assessment**: Formal clinical submissions (e.g. MoCA, MMSE, ADAS-Cog score summaries, neurologist evaluation).
