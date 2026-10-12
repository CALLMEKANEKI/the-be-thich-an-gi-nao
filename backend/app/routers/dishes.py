import logging

from fastapi import APIRouter, HTTPException

from app.services.ingredient_agent import get_or_generate_ingredients

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/dishes", tags=["dishes"])


@router.get("/{dish_id}/ingredients")
def dish_ingredients(dish_id: int):
    try:
        items = get_or_generate_ingredients(dish_id)
    except Exception:
        logger.exception("Sinh nguyên liệu thất bại cho dish %s", dish_id)
        raise HTTPException(status_code=503, detail="Chưa tạo được danh sách nguyên liệu, thử lại sau")
    if items is None:
        raise HTTPException(status_code=404, detail="Không tìm thấy món")
    return {"success": True, "data": {"dish_id": dish_id, "items": items}}