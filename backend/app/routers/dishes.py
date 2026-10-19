import logging

from fastapi import APIRouter, HTTPException, Query

from app.services import dish_service
from app.services.ingredient_agent import get_or_generate_ingredients

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/dishes", tags=["dishes"])


def _unavailable(action: str) -> HTTPException:
    logger.exception("%s thất bại", action)
    return HTTPException(status_code=503, detail="Chưa tải được dữ liệu món ăn, thử lại sau")


@router.get("")
def list_dishes(
    q: str | None = Query(None, max_length=100),
    category: str | None = Query(None, max_length=50),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    try:
        total, items = dish_service.search_dishes(q, category, limit, offset)
    except Exception:
        raise _unavailable("Lấy danh sách món")
    return {"success": True, "data": {"total": total, "limit": limit, "offset": offset, "items": items}}


# PHẢI đứng trước "/{dish_id}", nếu không "categories" bị hiểu là dish_id
@router.get("/categories")
def dish_categories():
    try:
        categories = dish_service.list_categories()
    except Exception:
        raise _unavailable("Lấy nhóm món")
    return {"success": True, "data": categories}


@router.get("/{dish_id}")
def dish_detail(dish_id: int):
    try:
        dish = dish_service.get_dish(dish_id)
    except Exception:
        raise _unavailable("Lấy chi tiết món")
    if dish is None:
        raise HTTPException(status_code=404, detail="Không tìm thấy món")
    return {"success": True, "data": dish}


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