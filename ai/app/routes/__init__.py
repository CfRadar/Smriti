from .prediction import router as prediction_router
from .speech import router as speech_router
from .personalization import router as personalization_router
from .analysis import router as analysis_router

__all__ = [
    "prediction_router",
    "speech_router",
    "personalization_router",
    "analysis_router",
]