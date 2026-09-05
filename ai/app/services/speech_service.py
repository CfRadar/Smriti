from typing import List, Dict, Any

class SpeechService:
    HESITATION_MARKERS = {"um", "uh", "er", "ah", "hmm", "...", "like"}

    @classmethod
    def extract_linguistic_markers(cls, transcript: str) -> Dict[str, Any]:
        """Calculates hesitation count, pauses, and speech fluency from transcripts."""
        words = transcript.strip().split() if transcript else []
        total_words = len(words)
        
        hesitations = [w.lower().strip(".,!?") for w in words if w.lower().strip(".,!?") in cls.HESITATION_MARKERS]
        hesitation_ratio = len(hesitations) / max(total_words, 1)

        fluency_score = max(30.0, min(100.0, round((1.0 - (hesitation_ratio * 3.0)) * 100, 1)))

        return {
            "total_words": total_words,
            "hesitation_count": len(hesitations),
            "hesitation_ratio": round(hesitation_ratio, 3),
            "fluency_score": fluency_score,
            "estimated_wpm": round(total_words / 0.5) if total_words > 0 else 0,  # assumption ~30s sample
        }
