"""
task.py
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.schemas.task import TaskOut, TaskCreate, TaskUpdate
from app.crud import task as crud_task
from app.api.deps import get_db, get_current_user

router = APIRouter()


@router.post("/", response_model=TaskOut, status_code=status.HTTP_201_CREATED)
def create_new_task(
    task_in: TaskCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Create a new task
    :param task_in:
    :param db:
    :param current_user:
    :return:
    """
    return crud_task.create_user_task(db=db, task_data=task_in, user_id=current_user.id)

@router.get("/", response_model=List[TaskOut])
def read_my_tasks(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    skip: int = 0,
    limit: int = 100
):
    """
    Get all tasks
    :param db:
    :param current_user:
    :param skip:
    :param limit:
    :return:
    """
    return crud_task.get_user_tasks(db=db, user_id=current_user.id, skip=skip, limit=limit)

@router.patch("/{task_id}", response_model=TaskOut)
def update_my_task(
    task_id: int,
    task_in: TaskUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Update a task
    :param task_id:
    :param task_in:
    :param db:
    :param current_user:
    :return:
    """
    task = crud_task.update_task(db=db, task_id=task_id, user_id=current_user.id, task_in=task_in)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Task not found or unauthorized")
    return task

@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_my_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Delete a task
    :param task_id:
    :param db:
    :param current_user:
    :return:
    """
    success = crud_task.delete_user_task(db=db, task_id=task_id, user_id=current_user.id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Task not found")
    return None
