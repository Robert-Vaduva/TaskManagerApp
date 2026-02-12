from fastapi import FastAPI

from app import database
from app.database import Base
from app.api import auth
from app.core.config import settings

Base.metadata.create_all(bind=database.engine)
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="My template App")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])

@app.get("/api/v1/salut")
async def hello():
    return {
        "status": "succes",
        "data": {
            "mesaj": "Salut de la FastAPI!",
            "versiune": "1.0.0",
            "server_status": "online"
        }
    }
