"""
category.py
"""
from typing import Optional
from pydantic import BaseModel

class CategoryBase(BaseModel):
    """
    Category base model
    """
    name: str
    color: str = "#4F46E5"

class CategoryCreate(CategoryBase):
    """
    Category create model
    """
    pass

class CategoryOut(CategoryBase):
    """
    Category output model
    """
    id: int
    owner_id: int

    class ConfigDict:
        from_attributes = True

class CategoryUpdate(BaseModel):
    """
    Category update model
    """
    name: Optional[str] = None
    color: Optional[str] = None
