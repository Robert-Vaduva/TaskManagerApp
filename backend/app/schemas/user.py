"""
user.py
"""
from typing import Optional
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


class UserBase(BaseModel):
    """
    User base class
    """
    email: EmailStr
    full_name: Optional[str] = None
    profile_image_url: Optional[str] = None


class UserCreate(UserBase):
    """
    User create class
    """
    password: str = Field(..., min_length=8, max_length=72)


class UserOut(UserBase):
    """
    User output class
    """
    id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    last_login: Optional[datetime] = None

    class Config:
        """
        Config class
        """
        from_attributes = True


class UserUpdate(BaseModel):
    """
    User update class
    """
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    password: Optional[str] = Field(None, min_length=8, max_length=72)
