from fastapi import APIRouter
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional

router = APIRouter(prefix="/analysis", tags=["Analysis"])

class CognitiveTrendRequest(BaseModel):
    patient_id: str
    timeframe_days: int = 30
    session_scores: List[float] = Field(default_factory=lambda: [80.0, 78.5, 76.0, 75.0])
    speech_fluency_rates: List[float] = Field(default_factory=lambda: [92.0, 90.5, 88.0, 89.0])
    missed_reminders_count: int = 2

class CognitiveTrendResponse(BaseModel):
    patient_id: str
    trajectory: str  # "improving" | "stable" | "declining"
    decline_velocity_score: float
    confidence_interval: List[float]
    clinical_observations: List[str]
    recommended_interventions: List[str]

class BehavioralSummaryRequest(BaseModel):
    patient_id: str
    daily_interactions: int = 12
    task_adherence_percentage: float = 85.0
    sentiment_distribution: Dict[str, float] = Field(
        default_factory=lambda: {"positive": 0.65, "neutral": 0.25, "agitated": 0.10}
    )

class BehavioralSummaryResponse(BaseModel):
    patient_id: str
    stability_score: float
    anomaly_detected: bool
    risk_level: str  # "low" | "medium" | "high"
    insights: List[str]

@router.post("/cognitive-trends", response_model=CognitiveTrendResponse)
async def analyze_cognitive_trends(payload: CognitiveTrendRequest):
    """Analyzes multi-week cognitive performance indicators to map decline trajectories."""
    scores = payload.session_scores
    if len(scores) >= 2:
        diff = scores[-1] - scores[0]
        if diff < -5.0:
            trajectory = "declining"
            velocity = round(abs(diff) / len(scores), 2)
        elif diff > 5.0:
            trajectory = "improving"
            velocity = 0.0
        else:
            trajectory = "stable"
            velocity = round(abs(diff) / len(scores), 2)
    else:
        trajectory = "stable"
        velocity = 0.1

    observations = [
        f"Evaluated {len(scores)} recent game sessions over {payload.timeframe_days} days.",
        f"Speech fluency average: {round(sum(payload.speech_fluency_rates) / max(len(payload.speech_fluency_rates), 1), 1)}%",
        f"Missed reminders: {payload.missed_reminders_count}"
    ]

    interventions = [
        "Continue morning memory recall puzzles",
        "Encourage voice journal entries before bedtime"
    ]
    if trajectory == "declining":
        interventions.append("Recommend clinical neurology check-in for medication review")

    return CognitiveTrendResponse(
        patient_id=payload.patient_id,
        trajectory=trajectory,
        decline_velocity_score=velocity,
        confidence_interval=[0.82, 0.94],
        clinical_observations=observations,
        recommended_interventions=interventions,
    )

@router.post("/behavioral-summary", response_model=BehavioralSummaryResponse)
async def analyze_behavioral_summary(payload: BehavioralSummaryRequest):
    """Summarizes behavioral metrics and emotional stability flags for caregiver dashboards."""
    agitated_ratio = payload.sentiment_distribution.get("agitated", 0.0)
    anomaly = agitated_ratio > 0.35 or payload.task_adherence_percentage < 60.0

    risk_level = "low"
    if anomaly or agitated_ratio > 0.25:
        risk_level = "medium"
    if agitated_ratio > 0.40 and payload.task_adherence_percentage < 50.0:
        risk_level = "high"

    insights = [
        f"Daily interactions: {payload.daily_interactions}",
        f"Adherence rate: {payload.task_adherence_percentage}%",
        f"Primary mood state: {'calm/positive' if agitated_ratio < 0.2 else 'distressed'}"
    ]

    return BehavioralSummaryResponse(
        patient_id=payload.patient_id,
        stability_score=round(payload.task_adherence_percentage * 0.7 + (1.0 - agitated_ratio) * 30.0, 1),
        anomaly_detected=anomaly,
        risk_level=risk_level,
        insights=insights
    )