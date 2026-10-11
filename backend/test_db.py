from collections import Counter
from app.db.models import Dish
from app.db.session import SessionLocal

counter = Counter()
with SessionLocal() as db:
    for (ings,) in db.query(Dish.ingredients).filter(Dish.ingredients.isnot(None)).all():
        counter.update(i["normalized_name"] for i in ings)
    # for dish in db.query(Dish).filter(Dish.ingredients.isnot(None)).all():
    #     dish.ingredients = [
    #         {**i, "normalized_name": SYNONYMS.get(slugify(i["ingredient"]), slugify(i["ingredient"]))}
    #         for i in dish.ingredients
    #     ]
    # db.commit()
for name, n in sorted(counter.items()):
    print(f"{name}: {n}")