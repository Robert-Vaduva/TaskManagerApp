"""
config.py
"""
import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    """
    Settings class
    """
    PROJECT_NAME: str = "TaskManager API"
    DATABASE_URL: str = os.getenv("DATABASE_URL")
    SECRET_KEY: str = os.getenv("SECRET_KEY")
    ALGORITHM: str = os.getenv("ALGORITHM")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24
    ALLOWED_ORIGINS: list = os.getenv("ALLOWED_ORIGINS", "").split(",")
    API_V1_STR: str = "/api/v1"
    UPLOAD_DIR: str = "app/media/profile_pics"

settings = Settings()
