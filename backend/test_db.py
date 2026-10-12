from app.db.models import Dish
from app.db.session import SessionLocal

with SessionLocal() as db:
    for name in ("Cơm tấm", "Bún chả"):
        d = db.query(Dish).filter(Dish.name == name).first()
        print(name, [(i["ingredient"], i["normalized_name"], i["quantity"], i["unit"]) for i in d.ingredients])