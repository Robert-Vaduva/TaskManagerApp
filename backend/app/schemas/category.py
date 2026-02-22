from pydantic import BaseModel
from typing import Optional

class CategoryBase(BaseModel):
    name: str
    color: str = "#4F46E5"

class CategoryCreate(CategoryBase):
    pass

class CategoryOut(CategoryBase):
    id: int
    owner_id: int

    class Config:
        from_attributes = True

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    color: Optional[str] = None