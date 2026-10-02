import uuid
from fastapi import APIRouter
from app.schemas.spin import SpinRequest
from app.services.emotion_model import emotion_service
from app.services.ai_agent import recommend_dish

router = APIRouter(prefix="/api/v1/spin", tags=["spin"])

@router.post("/recommend")
def recommend(payload: SpinRequest):
    detected_mood = emotion_service.predict_emotion(payload.text)
    
    result = recommend_dish(detected_mood)
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
            "items": formatted_items
        }
    }