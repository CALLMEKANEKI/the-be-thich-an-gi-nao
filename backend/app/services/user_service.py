from sqlalchemy.exc import IntegrityError

from app.db.models import ShoppingList, SpinHistory, User
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
    
from app.db.models import ShoppingList, SpinHistory, User
from app.db.session import SessionLocal


def migrate_anonymous_data(device_id: str, user_id: int) -> dict:
    """
    Chuyển dữ liệu lịch sử quay và giỏ hàng từ tài khoản Khách (device_id) 
    sang tài khoản đã đăng nhập (user_id).
    """
    if not device_id:
        return {"spin_history": 0, "shopping_lists": 0}

    with SessionLocal() as db:
        with db.begin():
            # Tìm bản ghi User đại diện cho Khách ứng với device_id
            guest = (
                db.query(User)
                .filter(User.device_id == device_id, User.auth_user_id.is_(None))
                .with_for_update()
                .one_or_none()
            )
            
            # Nếu không tìm thấy hoặc tài khoản khách chính là user hiện tại
            if guest is None or guest.id == user_id:
                return {"spin_history": 0, "shopping_lists": 0}

            # 1. Chuyển đổi lịch sử quay spin_history
            history_count = (
                db.query(SpinHistory)
                .filter(SpinHistory.user_id == guest.id)
                .update({SpinHistory.user_id: user_id}, synchronize_session=False)
            )

            # 2. Chuyển đổi danh sách mua sắm shopping_list
            shopping_count = (
                db.query(ShoppingList)
                .filter(ShoppingList.user_id == guest.id)
                .update({ShoppingList.user_id: user_id}, synchronize_session=False)
            )

            # 3. Dọn dẹp bản ghi Khách tạm thời
            db.delete(guest)

            return {
                "spin_history": history_count,
                "shopping_lists": shopping_count,
            }