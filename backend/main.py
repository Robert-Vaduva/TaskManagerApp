"""
main.py
"""
import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

from app.database import engine
from app.models.user import Base as UserBase
from app.models.task import Base as TaskBase
from app.models.category import Base as CategoryBase
from app.api import auth
from app.api.endpoints import user, task, category
from app.core.config import settings

UserBase.metadata.create_all(bind=engine)

app = FastAPI(title="TaskManager API")
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
origins=[
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:5000",
    "http://127.0.0.1:5000",
    "http://10.0.2.2:8000",
    "https://robert-vaduva.github.io",
    "https://robert-vaduva.github.io/TaskManagerApp"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/media", StaticFiles(directory="app/media"), name="media")
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(user.router, prefix="/users", tags=["Users"])
app.include_router(task.router, prefix="/tasks", tags=["Tasks"])
app.include_router(category.router, prefix="/categories", tags=["Category"])

@app.get("/api/v1/salut")
@app.get("/")
async def hello():
    """Basic Hello World."""
    return {
        "status": "succes",
        "data": {
            "mesaj": "Salut de la FastAPI!",
            "versiune": "1.0.0",
            "server_status": "online"
        }
    }
