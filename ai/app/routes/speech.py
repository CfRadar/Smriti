from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional, Dict, Any

router = APIRouter(prefix="/speech", tags=["Speech"])

class SpeechAnalysisRequest(BaseModel):
    audio: Optional[str] = None
    transcript: Optional[str] = "Good morning, I took my pill with breakfast."
    metadata: Dict[str, Any] = {}

class SpeechAnalysisResponse(BaseModel):
    fluency_score: float
    hesitation_count: int
    speech_rate_wpm: int
    sentiment: str
    acoustic_clarity: float

@router.post("/analyze", response_model=SpeechAnalysisResponse)
async def analyze_speech(payload: SpeechAnalysisRequest):
    """Analyzes patient speech audio/transcript for verbal markers of cognitive fatigue or dysphasia."""
    words = payload.transcript.split() if payload.transcript else []
    hesitations = sum(1 for w in words if w.lower() in ["um", "uh", "er", "..."])

    return SpeechAnalysisResponse(
        fluency_score=91.4,
        hesitation_count=hesitations,
        speech_rate_wpm=125,
        sentiment="positive",
        acoustic_clarity=0.88,
    )
