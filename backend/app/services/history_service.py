from app.db.models import Dish, SpinHistory
from app.db.session import SessionLocal
from app.services.user_service import get_or_create_user


def record_selection(auth_user_id: str, dish_id: int, mood: str | None) -> bool:
    """True nếu đã ghi, False nếu không có món."""
    user = get_or_create_user(auth_user_id)
    with SessionLocal() as db:
        if db.get(Dish, dish_id) is None:
            return False
        db.add(SpinHistory(user_id=user["id"], dish_id=dish_id, mood=mood))
        db.commit()
        return True


def list_history(auth_user_id: str, limit: int, offset: int) -> tuple[int, list[dict]]:
    user = get_or_create_user(auth_user_id)
    with SessionLocal() as db:
        base = (
            db.query(SpinHistory, Dish)
            .join(Dish, Dish.id == SpinHistory.dish_id)
            .filter(SpinHistory.user_id == user["id"])
        )
        total = base.count()
        rows = (
            base.order_by(SpinHistory.created_at.desc(), SpinHistory.id.desc())
            .offset(offset).limit(limit).all()
        )
        items = [
            {
                "id": h.id,
                "mood": h.mood,
                "created_at": h.created_at.isoformat() if h.created_at else None,
                "dish": {
                    "id": d.id, "name": d.name, "description": d.description or "",
                    "image_url": d.image_url or "", "category": d.category or "",
                },
            }
            for h, d in rows
        ]
    return total, items


def recent_dish_names(auth_user_id: str, limit: int = 8) -> list[str]:
    user = get_or_create_user(auth_user_id)
    with SessionLocal() as db:
        rows = (
            db.query(Dish.name)
            .join(SpinHistory, SpinHistory.dish_id == Dish.id)
            .filter(SpinHistory.user_id == user["id"])
            .order_by(SpinHistory.created_at.desc(), SpinHistory.id.desc())
            .limit(limit).all()
        )
    names: list[str] = []
    for (name,) in rows:
        if name not in names:   # bỏ trùng, giữ thứ tự gần nhất trước
            names.append(name)
    return names