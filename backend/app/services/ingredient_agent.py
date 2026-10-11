import logging

from google.genai import types

from app.db.models import Dish
from app.db.session import SessionLocal
from app.schemas.cart import IngredientListIn
from app.services.ai_agent import MODELS_TO_TRY, client
from app.services.ingredient_service import SYNONYMS, slugify

logger = logging.getLogger(__name__)


def _known_names(db) -> list[str]:
    """Tên nguyên liệu các món khác đã dùng, để Gemini tái sử dụng đúng tên."""
    names = set()
    for (ings,) in db.query(Dish.ingredients).filter(Dish.ingredients.isnot(None)).all():
        names.update(i["ingredient"] for i in ings)
    return sorted(names)


def _build_prompt(dish: Dish, known_names: list[str]) -> str:
    known = ", ".join(known_names[:200]) or "(chưa có)"
    return f"""
Bạn là trợ lý nấu ăn. Liệt kê nguyên liệu để nấu món "{dish.name}" ({dish.description}) cho 2 người ăn.

Quy tắc:
- name: tên tiếng Việt có dấu, ngắn gọn, không kèm cách chế biến (vd "Thịt bò", không phải "Thịt bò thái mỏng").
- quantity: số dương.
- unit: ưu tiên g hoặc ml; chỉ dùng quả/củ/tép/con/miếng/bó khi tự nhiên (trứng -> quả, tỏi -> tép).
- Bỏ qua gia vị có sẵn trong nhà: muối, đường, hạt nêm, tiêu, dầu ăn, nước lọc, đá.
- Nếu nguyên liệu đã có trong danh sách sau thì dùng ĐÚNG tên đó: {known}
- Tối đa 12 nguyên liệu.
"""


def _clean(raw_items) -> list[dict]:
    items = []
    for i in raw_items:
        slug = slugify(i.name)
        if i.quantity <= 0 or not slug:
            continue  # dòng sai thì bỏ
        items.append({
            "ingredient": " ".join(i.name.split()),
            "normalized_name": SYNONYMS.get(slug, slug),
            "quantity": round(i.quantity, 2),
            "unit": getattr(i.unit, "value", i.unit),
        })
    if not items:
        raise ValueError("Không có nguyên liệu hợp lệ")
    return items


def _generate(dish: Dish, known_names: list[str]) -> list[dict]:
    prompt = _build_prompt(dish, known_names)
    last_error = None
    for model in MODELS_TO_TRY:
        try:
            response = client.models.generate_content(
                model=model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=IngredientListIn,
                ),
            )
            if response.parsed is None:
                raise ValueError("Gemini không trả về dữ liệu đúng schema")
            return _clean(response.parsed.items)
        except Exception as e:
            logger.warning("Model %s lỗi: %s", model, e)
            last_error = e
    raise RuntimeError(f"Tất cả model đều lỗi: {last_error}")


def get_or_generate_ingredients(dish_id: int) -> list[dict] | None:
    with SessionLocal() as db:
        dish = db.get(Dish, dish_id)
        if dish is None:
            return None
        if dish.ingredients:  # đã có cache (không NULL, không rỗng)
            return dish.ingredients
        dish.ingredients = _generate(dish, _known_names(db))
        db.commit()
        return dish.ingredients