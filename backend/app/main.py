from fastapi import FastAPI
from app.routers import spin,places,dishes
from app.core.config import settings
from app.db.session import engine, Base

Base.metadata.create_all(bind= engine)
app = FastAPI(title="Thế bé thích ăn gì nào? API", version="v1")
app.include_router(spin.router)
app.include_router(places.router)
app.include_router(dishes.router)

@app.get("/health")
def health_check():
    return {"status": "ok"}

