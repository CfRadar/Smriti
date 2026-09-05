from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import (
    prediction_router,
    speech_router,
    personalization_router,
    analysis_router,
)

app = FastAPI(
    title="Smriti AI Cognitive & Speech Engine",
    description="Cognitive decline risk estimation, speech biomarker analytics, and memory recall synthesis for dementia care.",
    version="1.0.0",
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Route registration
app.include_router(prediction_router)
app.include_router(speech_router)
app.include_router(personalization_router)
app.include_router(analysis_router)

@app.get("/")
async def root():
    return {
        "service": "Smriti AI Engine",
        "status": "online",
        "docs_url": "/docs",
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "smriti-ai",
        "version": "1.0.0",
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
