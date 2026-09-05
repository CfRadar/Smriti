import sys
import os

# Ensure ai directory is in python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

def test_api_routes_import():
    from app.services.prediction_service import PredictionService
    from app.services.speech_service import SpeechService
    from app.inference.engine import engine

    # Test prediction calculation logic
    result = PredictionService.calculate_risk_score(game_scores=[85, 90, 80], adherence_rate=0.9, age=68)
    assert "risk_score" in result
    assert result["risk_category"] in ["low", "moderate", "high"]

    # Test speech calculation logic
    speech_res = SpeechService.extract_linguistic_markers("Hello, um, I am taking my medicine, uh, now.")
    assert speech_res["hesitation_count"] == 2
    assert speech_res["fluency_score"] > 0

    # Test inference engine
    engine_res = engine.run_inference("dementia_risk", {"score": 85})
    assert engine_res["prediction_status"] == "success"

    # Test app import if fastapi is installed
    try:
        from app.main import app
        assert app.title == "Smriti AI Cognitive & Speech Engine"
        print("FastAPI app verified successfully.")
    except ImportError as e:
        print(f"Note: FastAPI optional dependency not yet installed in host environment ({e}), service modules verified.")

    print("All Smriti AI core unit tests passed!")

if __name__ == "__main__":
    test_api_routes_import()
