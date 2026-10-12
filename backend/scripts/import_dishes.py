import csv
import unicodedata

from app.db.models import Dish
from app.db.session import SessionLocal

CSV_PATH = "data/dishes.csv"  # đổi đúng tên file thật của bạn
UPDATE_EXISTING = True        # False = món đã có thì bỏ qua hẳn


def name_key(name: str) -> str:
    """Khoá so sánh: bỏ khoảng trắng thừa, thống nhất Unicode, không phân biệt hoa/thường."""
    return unicodedata.normalize("NFC", " ".join(name.split())).casefold()


def clean(value) -> str:
    return " ".join((value or "").split())


inserted = updated = skipped = 0
seen = set()

with SessionLocal() as db:
    existing = {name_key(d.name): d for d in db.query(Dish).all()}

    with open(CSV_PATH, "r", encoding="utf-8-sig") as f:
        for line_no, row in enumerate(csv.DictReader(f), start=2):
            name = clean(row.get("name"))
            if not name:
                continue  # dòng trống

            key = name_key(name)
            if key in seen:
                print(f"[trùng trong file] dòng {line_no}: {name}")
                skipped += 1
                continue
            seen.add(key)

            description = clean(row.get("description") or row.get("decription"))
            category = clean(row.get("category"))
            image_url = clean(row.get("image_url"))

            dish = existing.get(key)
            if dish is None:
                db.add(Dish(name=name, description=description,
                            category=category, image_url=image_url))
                inserted += 1
            elif UPDATE_EXISTING:
                changed = False
                for field, value in (("description", description),
                                     ("category", category),
                                     ("image_url", image_url)):
                    if value and getattr(dish, field) != value:
                        setattr(dish, field, value)
                        changed = True
                if changed:
                    updated += 1
                else:
                    skipped += 1
            else:
                skipped += 1

    db.commit()

print(f"Thêm mới: {inserted} | Cập nhật: {updated} | Bỏ qua: {skipped}")