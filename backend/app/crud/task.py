"""
task.py
"""
from sqlalchemy.orm import Session
from app.models.task import Task
from app.schemas.task import TaskCreate, TaskUpdate


def create_user_task(db: Session, task_data: TaskCreate, user_id: int):
    """
    Create new task
    :param db:
    :param task_data:
    :param user_id:
    :return:
    """
    db_task = Task(**task_data.model_dump(), owner_id=user_id)
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task


def get_user_tasks(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    """
    Get tasks
    :param db:
    :param user_id:
    :param skip:
    :param limit:
    :return:
    """
    return db.query(Task).filter(Task.owner_id == user_id).offset(skip).limit(limit).all()


def update_task(db: Session, task_id: int, user_id: int, task_in: TaskUpdate):
    """
    Update task
    :param db:
    :param task_id:
    :param user_id:
    :param task_in:
    :return:
    """
    db_task = db.query(Task).filter(Task.id == task_id, Task.owner_id == user_id).first()
    if not db_task:
        return None

    update_data = task_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_task, field, value)

    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task


def delete_user_task(db: Session, task_id: int, user_id: int):
    """
    Delete task
    :param db:
    :param task_id:
    :param user_id:
    :return:
    """
    db_task = db.query(Task).filter(Task.id == task_id, Task.owner_id == user_id).first()
    if db_task:
        db.delete(db_task)
        db.commit()
        return True
    return False
