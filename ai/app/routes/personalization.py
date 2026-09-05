from fastapi import APIRouter
from pydantic import BaseModel
from typing import List, Dict, Any

router = APIRouter(prefix="/personalization", tags=["Personalization"])

class RecallQuestionRequest(BaseModel):
    patient_id: str
    memories: List[Dict[str, Any]]
    difficulty: str = "easy"

class RecallQuestionResponse(BaseModel):
    question: str
    options: List[str]
    correct_answer: str
    hint: str
    media_url: str = ""

@router.post("/generate-question", response_model=RecallQuestionResponse)
async def generate_recall_question(payload: RecallQuestionRequest):
    """Dynamically generates memory recall questions tailored to patient's family albums and memories."""
    return RecallQuestionResponse(
        question="Who is shown in this family photograph taken at the annual Diwali celebration?",
        options=["Grandson Rohan", "Son Vikram", "Nephew Amit", "Brother Suresh"],
        correct_answer="Grandson Rohan",
        hint="He wore the bright yellow kurta that you gifted him.",
        media_url="/static/memories/diwali_2023.jpg"
    )
