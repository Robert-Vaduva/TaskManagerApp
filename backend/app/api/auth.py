from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app import database, models, schemas
from app.core import security
from datetime import datetime, timedelta
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from jose import JWTError, jwt

from app.models.user import User
from app import database
from app.core import security
from app.schemas.user import UserCreate
from app.database import SessionLocal, engine, Base
from app.api import auth
from app.core.config import settings

router = APIRouter()


def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def get_current_user(token: str, db: Session = Depends(database.get_db)):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Nu am putut valida token-ul",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise credentials_exception
    return user


@router.post("/register")
def register_user(user_data: UserCreate, db: Session = Depends(database.get_db)):
    db_user = db.query(User).filter(User.email == user_data.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email deja înregistrat")

    # CRIPTĂM PAROLA AICI
    hashed_pass = security.get_password_hash(user_data.password)

    new_user = User(
        email=user_data.email,
        full_name=user_data.full_name,
        hashed_password=hashed_pass  # Salvăm hash-ul, nu parola reală
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"status": "success", "message": "Cont creat în siguranță"}


@router.post("/login")
def login(user_data: UserCreate, db: Session = Depends(database.get_db)):
    # 1. Căutăm utilizatorul
    user = db.query(User).filter(User.email == user_data.email).first()
    if not user:
        raise HTTPException(status_code=400, detail="Email sau parolă incorectă")

    # 2. Verificăm parola folosind funcția nouă din security.py
    if not security.verify_password(user_data.password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Email sau parolă incorectă")

    # 3. Generăm token-ul
    token = create_access_token(data={"sub": user.email})
    return {"status": "success", "access_token": token, "token_type": "bearer"}


# RUTĂ PROTEJATĂ: Doar utilizatorii logați o pot accesa
@router.get("/users/me")
def read_users_me(current_user: User = Depends(get_current_user)):
    return {
        "email": current_user.email,
        "full_name": current_user.full_name,
        "is_active": current_user.is_active
    }