from fastapi import FastAPI
from app.routers import spin,places
from app.core.config import settings
app = FastAPI(title="Thế bé thích ăn gì nào? API", version="v1")
app.include_router(spin.router)
app.include_router(places.router)

@app.get("/health")
def health_check():
    return {"status": "ok"}

