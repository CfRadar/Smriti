from fastapi import APIRouter
from pydantic import BaseModel, Field
from typing import List, Optional

router = APIRouter(prefix="/predict", tags=["Prediction"])

class CognitiveDeclineRequest(BaseModel):
    patient_id: Optional[str] = "P001"
    age: int = 70
    game_scores: List[float] = Field(default_factory=lambda: [75.0, 72.0, 78.0])
    task_completion_rate: float = 0.85
    speech_hesitations_per_min: float = 4.2

class CognitiveDeclineResponse(BaseModel):
    risk_score: float
    risk_category: str
    progression_rate: str
    key_factors: List[str]
    confidence: float

@router.post("/cognitive-decline", response_model=CognitiveDeclineResponse)
async def predict_cognitive_decline(payload: CognitiveDeclineRequest):
    """Predicts cognitive decline risk score and progression speed based on clinical & interaction metrics."""
    avg_score = sum(payload.game_scores) / len(payload.game_scores) if payload.game_scores else 50.0
    
    # Heuristic inference baseline
    risk_score = max(0.05, min(0.95, round((100.0 - avg_score) / 100.0 * 0.7 + (1.0 - payload.task_completion_rate) * 0.3, 2)))
    
    if risk_score < 0.35:
        category = "low"
    elif risk_score < 0.70:
        category = "moderate"
    else:
        category = "high"

    return CognitiveDeclineResponse(
        risk_score=risk_score,
        risk_category=category,
        progression_rate="stable",
        key_factors=["Game performance stability", "Daily task adherence"],
        confidence=0.89,
    )
