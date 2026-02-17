from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.schemas.user import UserOut, UserUpdate
from app.models.user import User
from app.api.deps import get_db, get_current_user

router = APIRouter()


@router.get("/me")
def read_users_me(current_user: User = Depends(get_current_user)):
    return {
        "email": current_user.email,
        "full_name": current_user.full_name,
        "is_active": current_user.is_active
    }

@router.put("/me", response_model=UserOut)
def update_user_me(
        user_update: UserUpdate,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    if user_update.email:
        email_exists = db.query(User).filter(User.email == user_update.email).first()
        if email_exists and email_exists.id != current_user.id:
            raise HTTPException(status_code=400, detail="Email deja înregistrat")
        current_user.email = user_update.email

    if user_update.full_name:
        current_user.full_name = user_update.full_name

    db.commit()
    db.refresh(current_user)
    return current_user