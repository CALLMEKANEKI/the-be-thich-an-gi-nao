import unicodedata
from collections import Counter

from app.db.models import Dish
from app.db.session import SessionLocal
from app.services.ingredient_service import slugify


def _to_dict(dish: Dish) -> dict:
    return {
        "id": dish.id,
        "name": dish.name,
        "description": dish.description or "",
        "image_url": dish.image_url or "",
        "category": dish.category or "",
    }


def load_all_dishes() -> list[dict]:
    with SessionLocal() as db:
        return [_to_dict(d) for d in db.query(Dish).all()]


def _category_key(category: str) -> str:
    # NFC + bỏ khoảng trắng thừa + không phân biệt hoa/thường (dữ liệu từ Google Sheet hay lệch)
    return " ".join(unicodedata.normalize("NFC", category).split()).casefold()


def filter_and_sort(dishes: list[dict], q: str | None = None, category: str | None = None) -> list[dict]:
    result = dishes
    if category:
        wanted = _category_key(category)
        result = [d for d in result if _category_key(d["category"]) == wanted]
    if q:
        needle = slugify(q)
        if needle:  # q chỉ toàn dấu câu thì bỏ qua bộ lọc
            tokens = [t for t in needle.split("_") if t]
            def matches(d_name: str) -> bool:
                s_name = slugify(d_name)
                return needle in s_name or all(t in s_name for t in tokens)
            result = [d for d in result if matches(d["name"])]
    return sorted(result, key=lambda d: (slugify(d["name"]), d["id"]))


def build_categories(dishes: list[dict]) -> list[dict]:
    groups: dict[str, dict] = {}
    for d in dishes:
        if not d["category"].strip():
            continue
        group = groups.setdefault(_category_key(d["category"]), {"names": Counter(), "count": 0})
        group["names"][" ".join(d["category"].split())] += 1
        group["count"] += 1
    result = [{"name": g["names"].most_common(1)[0][0], "count": g["count"]} for g in groups.values()]
    return sorted(result, key=lambda c: (-c["count"], slugify(c["name"])))


def search_dishes(q: str | None, category: str | None, limit: int, offset: int) -> tuple[int, list[dict]]:
    matched = filter_and_sort(load_all_dishes(), q, category)
    return len(matched), matched[offset: offset + limit]


def list_categories() -> list[dict]:
    return build_categories(load_all_dishes())


def get_dish(dish_id: int) -> dict | None:
    with SessionLocal() as db:
        dish = db.get(Dish, dish_id)
        return _to_dict(dish) if dish else None