"""
task.py
"""
from typing import Optional
from datetime import datetime
from pydantic import BaseModel

from app.models.task import TaskPriority
from app.schemas.category import CategoryOut


class TaskBase(BaseModel):
    """
    Task base model
    """
    title: str
    description: Optional[str] = None
    priority: TaskPriority = TaskPriority.MEDIUM
    category_id: Optional[int] = None
    deadline: Optional[datetime] = None


class TaskCreate(TaskBase):
    """
    Task create model
    """
    pass


class TaskOut(TaskBase):
    """
    Task output model
    """
    id: int
    owner_id: int
    is_completed: bool
    created_at: datetime
    updated_at: datetime
    category_rel: Optional[CategoryOut] = None

    class Config:
        """
        Config class
        """
        from_attributes = True

class TaskUpdate(BaseModel):
    """
    Task update model
    """
    title: Optional[str] = None
    description: Optional[str] = None
    priority: Optional[TaskPriority] = None
    category_id: Optional[int] = None
    is_completed: Optional[bool] = None
    deadline: Optional[datetime] = None

    class Config:
        """
        Config class
        """
        from_attributes = True
