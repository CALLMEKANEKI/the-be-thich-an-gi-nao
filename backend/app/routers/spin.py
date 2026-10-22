import uuid
from fastapi import APIRouter
from app.schemas.spin import SpinRequest
from app.services.emotion_model import emotion_service
from app.services.ai_agent import recommend_dish
import logging
from fastapi import Depends, HTTPException, Query
from app.core.auth import get_optional_claims, get_required_claims
from app.schemas.spin import SelectRequest
from app.services import history_service
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/spin", tags=["spin"])

def _recent_names(claims: dict | None) -> list[str]:
    if claims is None:
        return []
    try:
        return history_service.recent_dish_names(claims["sub"])
    except Exception:
        logger.warning("Không đọc được lịch sử Spin, bỏ qua", exc_info=True)
        return []
    
@router.post("/recommend")
def recommend(payload: SpinRequest, claims: dict | None = Depends(get_optional_claims)):
    detected_mood = emotion_service.predict_emotion(payload.text)
    recent_names = _recent_names(claims)
    
    result = recommend_dish(detected_mood, recent_names=recent_names)
    recommendations_raw = result.get("recommendations", [])
    
    formatted_items = []
    for item in recommendations_raw:
        dish = item["dish"]
        
        ingredients_list = getattr(dish, "ingredients", [])
        if isinstance(ingredients_list, str):
            ingredients_list = [i.strip() for i in ingredients_list.split(",") if i.strip()]

        formatted_items.append({
            "dish": {
                "id": dish.id,
                "name": dish.name,
                "description": dish.description,
                "image_url": getattr(dish, "image_url", ""),
                "category": getattr(dish, "category", "Khác"),
            },
            "reason": item["reason"],
            "confidence": item["confidence"],
            "ingredients": ingredients_list,
            "available_modes": ["restaurant", "cook"]
        })
    
    return {
        "success": True,
        "data": {
            "recommendation_id": f"rec_{uuid.uuid4().hex[:8]}",
            "detected_mood": detected_mood,
            "total": len(formatted_items),
            "wheel_options": formatted_items
        }
    }
    
@router.post("/select")
def select(payload: SelectRequest, claims: dict | None = Depends(get_optional_claims)):
    if claims is None:   # khách: không lưu, app không cần rẽ nhánh
        return {"success": True, "data": {"recorded": False}}
    try:
        recorded = history_service.record_selection(claims["sub"], payload.dish_id, payload.mood)
    except Exception:
        logger.exception("Ghi lịch sử Spin thất bại")
        raise HTTPException(status_code=503, detail="Chưa ghi được lịch sử, thử lại sau")
    if not recorded:
        raise HTTPException(status_code=404, detail="Không tìm thấy món")
    return {"success": True, "data": {"recorded": True}}


@router.get("/history")
def history(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    claims: dict = Depends(get_required_claims),
):
    try:
        total, items = history_service.list_history(claims["sub"], limit, offset)
    except Exception:
        logger.exception("Đọc lịch sử Spin thất bại")
        raise HTTPException(status_code=503, detail="Chưa tải được lịch sử, thử lại sau")
    return {"success": True, "data": {"total": total, "limit": limit, "offset": offset, "items": items}}