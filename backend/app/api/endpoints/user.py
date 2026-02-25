"""
user.py
"""
import os
import shutil
from datetime import datetime
from fastapi import APIRouter, UploadFile, File, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.schemas.user import UserOut, UserUpdate
from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.core import security

router = APIRouter()


@router.get("/me")
def read_users_me(current_user: User = Depends(get_current_user)):
    """
    Read user info
    :param current_user:
    :return:
    """
    return {
        "id": current_user.id,
        "email": current_user.email,
        "full_name": current_user.full_name,
        "profile_image_url": current_user.profile_image_url,
        "created_at": current_user.created_at,
        "updated_at": current_user.updated_at,
        "last_login": current_user.last_login,
        "is_active": current_user.is_active
    }

@router.put("/me", response_model=UserOut)
def update_user_me(
        user_update: UserUpdate,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    """
    Update user info
    :param user_update:
    :param db:
    :param current_user:
    :return:
    """
    if user_update.email:
        email_exists = db.query(User).filter(User.email == user_update.email).first()
        if email_exists and email_exists.id != current_user.id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                                detail="Email deja înregistrat")
        current_user.email = user_update.email

    if user_update.full_name:
        current_user.full_name = user_update.full_name

    if user_update.password:
        current_user.hashed_password = security.get_password_hash(user_update.password)

    db.commit()
    db.refresh(current_user)
    return current_user


@router.post("/me/upload-avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Upload avatar
    :param file:
    :param current_user:
    :param db:
    :return:
    """
    allowed_extensions = ["jpg", "jpeg", "png"]
    extension = file.filename.split(".")[-1].lower()
    if extension not in allowed_extensions:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Format neacceptat")

    file_name = f"user_{current_user.id}_{int(datetime.now().timestamp())}.{extension}"
    file_path = os.path.join(settings.UPLOAD_DIR, file_name)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    relative_path = f"media/profile_pics/{file_name}"
    current_user.profile_image_url = relative_path
    db.commit()

    return {"info": "Imagine încărcată cu succes", "url": relative_path}
