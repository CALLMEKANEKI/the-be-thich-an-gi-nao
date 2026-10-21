from sqlalchemy.exc import IntegrityError

from app.db.models import User
from app.db.session import SessionLocal


def get_or_create_user(auth_user_id: str) -> dict:
    with SessionLocal() as db:
        user = db.query(User).filter(User.auth_user_id == auth_user_id).first()
        if user is None:
            user = User(auth_user_id=auth_user_id)
            db.add(user)
            try:
                db.commit()
            except IntegrityError:   # hai request đầu tiên cùng lúc: bên kia đã tạo trước
                db.rollback()
                user = db.query(User).filter(User.auth_user_id == auth_user_id).one()
            else:
                db.refresh(user)
        return {"id": user.id, "auth_user_id": str(user.auth_user_id)}