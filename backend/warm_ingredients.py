import time

from app.db.models import Dish
from app.db.session import SessionLocal
from app.services.ingredient_agent import get_or_generate_ingredients

with SessionLocal() as db:
    ids = [d.id for d in db.query(Dish).filter(Dish.ingredients.is_(None)).order_by(Dish.id).all()]

print(f"Cần sinh nguyên liệu cho {len(ids)} món")
for dish_id in ids:
    try:
        items = get_or_generate_ingredients(dish_id)
        print(f"[OK] dish {dish_id}: {len(items)} nguyên liệu")
    except Exception as e:
        print(f"[LỖI] dish {dish_id}: {e}")
    time.sleep(4)  