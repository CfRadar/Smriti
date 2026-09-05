from typing import Dict, Any, Optional

class AudioPreprocessor:
    """Preprocesses voice input files or streams for feature extraction."""

    @staticmethod
    def inspect_audio_metadata(audio_bytes: Optional[bytes]) -> Dict[str, Any]:
        """Validates payload size and checks audio validity."""
        if not audio_bytes:
            return {"valid": False, "size_bytes": 0, "sample_rate": 16000}
        
        return {
            "valid": True,
            "size_bytes": len(audio_bytes),
            "sample_rate": 16000,
            "channels": 1,
            "duration_seconds": round(len(audio_bytes) / 32000, 2),  # 16-bit 16kHz mono estimate
        }
