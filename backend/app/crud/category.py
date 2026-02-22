from sqlalchemy.orm import Session
from app.models.category import Category
from app.schemas.category import CategoryCreate, CategoryUpdate


def create_category(db: Session, category_data: CategoryCreate, user_id: int):
    db_category = Category(**category_data.model_dump(), owner_id=user_id)
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category


def get_user_categories(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.query(Category).filter(Category.owner_id == user_id).offset(skip).limit(limit).all()


def get_category_by_id(db: Session, category_id: int, user_id: int):
    return db.query(Category).filter(Category.id == category_id,Category.owner_id == user_id).first()


def update_category(db: Session, category_id: int, category_data: CategoryUpdate, user_id: int):
    db_category = db.query(Category).filter(
        Category.id == category_id,
        Category.owner_id == user_id
    ).first()

    if not db_category:
        return None

    update_data = category_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_category, key, value)

    db.commit()
    db.refresh(db_category)
    return db_category


def delete_category(db: Session, category_id: int, user_id: int):
    db_category = db.query(Category).filter(
        Category.id == category_id,
        Category.owner_id == user_id
    ).first()

    if db_category:
        db.delete(db_category)
        db.commit()
        return True
    return False
