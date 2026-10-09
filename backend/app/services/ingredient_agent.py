from google.genai import types
from app.db.session import SessionLocal
from app.db.models import Dish
from app.schemas.cart import IngredientListIn
from app.services.ai_agent import client
from app.services.ingredient_service import normalize_ingredient

MODELS = [...]  # chép đúng danh sách model đang chạy được trong ai_agent.py


def _known_names(db) -> list[str]:
    names = set()
    for (ings,) in db.query(Dish.ingredients).filter(Dish.ingredients.isnot(None)).all():
        names.update(i["ingredient"] for i in ings)
    return sorted(names)


def _generate(dish: Dish, known_names: list[str]) -> list[dict]:
    prompt = f"""
Bạn là trợ lý nấu ăn. Liệt kê nguyên liệu để nấu món "{dish.name}" ({dish.description}) cho 2 người ăn.

Quy tắc:
- ingredient: tên tiếng Việt có dấu, ngắn gọn, không kèm cách chế biến (vd "Thịt bò", không phải "Thịt bò thái mỏng").
- quantity: số dương. unit: ưu tiên g hoặc ml; chỉ dùng quả/củ/tép/con/miếng/bó khi tự nhiên (trứng -> quả, tỏi -> tép).
- Bỏ qua gia vị có sẵn trong nhà: muối, đường, hạt nêm, tiêu, dầu ăn, nước lọc, đá.
- Nếu nguyên liệu đã có trong danh sách sau thì dùng ĐÚNG tên đó: {known_names}
- Tối đa 12 nguyên liệu.
"""
    last_error = None
    for model in MODELS:
        try:
            response = client.models.generate_content(

                model=model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=IngredientListIn,
                ),
            )
            return [normalize_ingredient(i).model_dump() for i in response.parsed.items]
        except Exception as e:
            last_error = e
    raise RuntimeError(f"Tất cả model đều lỗi: {last_error}")


def get_or_generate_ingredients(dish_id: int) -> list[dict] | None:
    with SessionLocal() as db:
        dish = db.get(Dish, dish_id)
        if dish is None:
            return None
        if dish.ingredients is not None:
            return dish.ingredients  # đã có cache

        dish.ingredients = _generate(dish, _known_names(db))
        db.commit()
        return dish.ingredients