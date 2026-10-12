from collections import defaultdict

from app.db.models import Dish
from app.db.session import SessionLocal

# normalized_name -> tên hiển thị (viết thường) -> tập dish_id
names = defaultdict(lambda: defaultdict(set))

with SessionLocal() as db:
    dishes = db.query(Dish).all()
    missing = [d.name for d in dishes if not d.ingredients]
    for d in dishes:
        for i in d.ingredients or []:
            display = " ".join(i["ingredient"].lower().split())
            names[i["normalized_name"]][display].add(d.id)

print(f"{len(dishes)} món, chưa có nguyên liệu: {missing}\n")
print(f"{len(names)} normalized_name khác nhau\n")

lines = []
for key in sorted(names):
    variants = names[key]
    total = len(set().union(*variants.values()))
    shown = "; ".join(f"{n} ({len(ds)})" for n, ds in sorted(variants.items()))
    lines.append(f"{key} | {total} món | {shown}")
    if len(variants) > 1:
        print(f"[SLUG TRÙNG] {key}: {list(variants)}")

with open("ingredient_names.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print("Đã ghi ingredient_names.txt")