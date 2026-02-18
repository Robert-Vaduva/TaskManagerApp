from fastapi import FastAPI

from app import database
from app.database import Base
from app.api import auth
from app.api.endpoints import user, task
from app.core.config import settings

Base.metadata.create_all(bind=database.engine)
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="TaskManager API")

app.add_middleware(
    CORSMiddleware,
    #rova allow_origins=settings.ALLOWED_ORIGINS,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(user.router, prefix="/users", tags=["Users"])
app.include_router(task.router, prefix="/tasks", tags=["Tasks"])

@app.get("/api/v1/salut")
@app.get("/")
async def hello():
    return {
        "status": "succes",
        "data": {
            "mesaj": "Salut de la FastAPI!",
            "versiune": "1.0.0",
            "server_status": "online"
        }
    }
