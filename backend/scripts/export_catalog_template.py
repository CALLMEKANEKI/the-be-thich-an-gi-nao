import csv
from collections import defaultdict
from statistics import median
import sys
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND_DIR))

from app.db.models import Dish
from app.db.session import SessionLocal

info = defaultdict(lambda: {"names": defaultdict(int), "qtys": [], "dishes": set()})

with SessionLocal() as db:
    for d in db.query(Dish).all():
        for i in d.ingredients or []:
            k = (i["normalized_name"], i["unit"])
            info[k]["names"][" ".join(i["ingredient"].split())] += 1
            info[k]["qtys"].append(i["quantity"])
            info[k]["dishes"].add(d.id)

rows = []
for n, ((key, unit), v) in enumerate(sorted(info.items()), start=1):
    rows.append({
        "sku": f"SKU{n:03d}",
        "normalized_name": key,
        "ingredient": max(v["names"], key=v["names"].get),  # tên hay gặp nhất
        "unit": unit,
        "so_mon_dung": len(v["dishes"]),
        "luong_thuong_dung": round(median(v["qtys"]), 1),
        "product_name": "",
        "pack_size": "",
        "price_vnd": "",
        "search_keyword": "",
    })

with open(BACKEND_DIR / "sku_catalog_template.csv", "w", encoding="utf-8-sig", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
    writer.writeheader()
    writer.writerows(rows)
print(f"{len(rows)} dòng -> sku_catalog_template.csv")