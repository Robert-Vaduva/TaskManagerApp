from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.api.deps import get_db, get_current_user
from app.schemas.category import CategoryCreate, CategoryOut, CategoryUpdate
from app.models.user import User
from app.crud import category as crud_category

router = APIRouter()


@router.post("/", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
def create_new_category(
    category: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return crud_category.create_category(db, category_data=category, user_id=current_user.id)


@router.get("/", response_model=List[CategoryOut])
def read_my_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return crud_category.get_user_categories(db, user_id=current_user.id)


@router.patch("/{category_id}", response_model=CategoryOut)
def update_my_category(
    category_id: int,
    category_update: CategoryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    updated_cat = crud_category.update_category(
        db,
        category_id=category_id,
        category_data=category_update,
        user_id=current_user.id
    )
    if not updated_cat:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found"
        )
    return updated_cat


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_my_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    success = crud_category.delete_category(db, category_id=category_id, user_id=current_user.id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found"
        )
    return None