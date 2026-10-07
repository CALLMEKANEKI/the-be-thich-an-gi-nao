import json
from google import genai
from google.genai import types
from app.core.config import settings
from app.db.session import SessionLocal
from app.db.models import Dish
from app.services.weather_service import get_current_weather

client = genai.Client(api_key=settings.gemini_api_key)

def build_dish_list_text(dishes: list[Dish]) -> str:
    lines = [f"- {d.name} (id={d.id}, category={d.category}): {d.description}" for d in dishes]
    return "\n".join(lines)

def recommend_dish(mood: str, lat: float = None, lon: float = None) -> dict:
    with SessionLocal() as db:
        dishes = db.query(Dish).all()
    
    if not dishes:
        raise ValueError("Danh sách món ăn trong Database đang trống!")

    dish_map = {d.id: d for d in dishes}
    dish_list_text = build_dish_list_text(dishes)

    weather_info = get_current_weather(lat, lon) if lat is not None and lon is not None else "không rõ"

    prompt = f"""
    Bạn là trợ lý gợi ý món ăn. Người dùng đang cảm thấy: "{mood}".
    Thời tiết hiện tại: {weather_info}
    Danh sách món ăn sẵn có:
    {dish_list_text}

    Hãy chọn ĐÚNG 10 món ăn phù hợp nhất từ danh sách trên (xắp xếp từ phù hợp nhất xuống ít phù hợp hơn).
    
    Trả về định dạng một JSON ARRAY gồm 10 object, mỗi object có các field:
    - "dish_id": (int) ID của món được chọn.
    - "reason": (string) Lý do chọn món ngắn gọn trong 1 câu bằng Tiếng Việt.
    - "confidence": (float) Độ tự tin từ 0 đến 1.
    """

    models_to_try = [
        "gemini-3.1-flash-lite",
        "gemini-2.5-flash-lite",
        "gemini-3.5-flash-lite"
    ]

    response_text = None
    
    for model_name in models_to_try:
        try:
            response = client.models.generate_content(
                model=model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json"
                )
            )
            response_text = response.text
            break  
        except Exception as e:
            print(f"[Warning] Model {model_name} bận ({e}), đang chuyển sang model tiếp theo...")
            continue

    if not response_text:
        raise Exception("Tất cả các model AI hiện đang bận, vui lòng thử lại sau!")

    raw_results = json.loads(response_text)
    
    if isinstance(raw_results, dict):
        raw_results = raw_results.get("recommendations", raw_results.get("dishes", []))

    recommended_list = []
    for item in raw_results:
        dish_id = item.get("dish_id")
        if dish_id in dish_map:
            recommended_list.append({
                "dish": dish_map[dish_id],
                "reason": item.get("reason", "Món ăn phù hợp với tâm trạng."),
                "confidence": item.get("confidence", 0.9)
            })

    if not recommended_list:
        for d in dishes[:10]:
            recommended_list.append({
                "dish": d,
                "reason": "Món ăn gợi ý mặc định.",
                "confidence": 0.8
            })

    return {
        "total": len(recommended_list),
        "recommendations": recommended_list
    }