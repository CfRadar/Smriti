from typing import List, Dict, Any

class PredictionService:
    @staticmethod
    def calculate_risk_score(game_scores: List[float], adherence_rate: float, age: int) -> Dict[str, Any]:
        """Calculates multi-factorial cognitive risk metric based on games, task adherence, and age."""
        mean_score = sum(game_scores) / len(game_scores) if game_scores else 50.0
        
        # Age baseline weighting
        age_factor = 0.1 if age < 65 else (0.2 if age < 80 else 0.3)
        
        # Risk score formula
        risk = ((100.0 - mean_score) / 100.0) * 0.5 + (1.0 - adherence_rate) * 0.3 + age_factor
        clamped_risk = max(0.05, min(0.95, round(risk, 2)))
        
        if clamped_risk < 0.35:
            category = "low"
        elif clamped_risk < 0.70:
            category = "moderate"
        else:
            category = "high"

        return {
            "risk_score": clamped_risk,
            "risk_category": category,
            "average_game_score": round(mean_score, 1),
            "adherence_rate": adherence_rate,
        }
