# Smriti (स्मृति) — Machine Learning & Cognitive AI Models

The Smriti AI microservice (`ai/`) hosts specialized machine learning pipelines and heuristic baselines tailored to dementia screening, longitudinal monitoring, and adaptive reminiscence therapy.

---

## 1. Cognitive Decline Risk Estimation Model

### 1.1 Objective
Predict early signs of cognitive deterioration and rate of progression using non-invasive everyday behavioral markers.

### 1.2 Input Features
- **Longitudinal Game Metrics**: Rolling 14-day and 30-day averages of accuracy, reaction latency, and mistake recurrence across cognitive domains (episodic memory, pattern recognition, executive sequencing).
- **Task Adherence**: Percentage of timely completed reminders (medication, meals, hydration).
- **Demographic & Baseline Priors**: Age, baseline MMSE/MoCA scores, disease stage.

### 1.3 Architecture
- **Inference Pipeline**: Feature normalizer -> Gradient Boosted Trees / Ensemble Classifier -> Calibrated Probability Estimator.
- **Output**:
  - `risk_score`: Continuous value between 0.05 and 0.95.
  - `risk_category`: Discrete risk bracket (`low`, `moderate`, `high`).
  - `progression_rate`: Trajectory velocity (`improving`, `stable`, `declining`).

---

## 2. Speech Biomarker & Acoustic Analyzer

### 2.1 Objective
Extract linguistic hesitation markers, pause lengths, and acoustic fluency indicators from patient daily voice interactions.

### 2.2 Biomarkers Analyzed
- **Linguistic**: Hesitation word frequency (`"um"`, `"uh"`, `"er"`, repetitions, prolonged fillers).
- **Temporal**: Speech rate (Words Per Minute / WPM), silence-to-speech ratio, pause duration distributions.
- **Acoustic**: Fundamental frequency variation (jitter, shimmer), voice stability, clarity.
- **Emotional Sentiment**: Valence-arousal classification for emotional agitation vs calm states.

---

## 3. Dynamic Reminiscence Question Generator

### 3.1 Objective
Synthesize tailored memory recall quizzes from family photo metadata to stimulate episodic recall and reinforce familiar bonds without causing patient anxiety.

### 3.2 Methodology
1. **Metadata Ingestion**: Family member relationships, photo tags, event locations, and personalized hints provided by caregivers.
2. **Contextual Prompting**: Generates multi-choice questions with 1 true option, 3 familiar but non-confusing distractors, and an affectionate, context-rich hint.
3. **Adaptive Difficulty**: Modulates question complexity (e.g., direct identity recall vs event time sequencing) based on current cognitive status.

---

## 4. Evaluation Metrics & Safety Fallbacks
- **Offline / Server Fallback**: If the neural network runtime is offline or unreachable, the service falls back to safe rule-based heuristic boundaries defined in `ai/app/services/`.
- **Privacy First**: Voice audio is processed locally or in memory without persistent raw audio storage unless explicitly consented by the legal caregiver.
