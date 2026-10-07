import httpx
from app.core.config import settings

WEATHER_URL = "https://api.openweathermap.org/data/2.5/weather"


def get_current_weather(lat: float, lon: float) -> str:
    try:
        response = httpx.get(WEATHER_URL, params={
            "lat": lat,
            "lon": lon,
            "appid": settings.weather_api_key,
            "units": "metric",
            "lang": "vi",
        }, timeout=5.0)
        response.raise_for_status()
        data = response.json()
        description = data["weather"][0]["description"]
        temp = data["main"]["temp"]
        return f"{description}, {temp}°C"
    except Exception:
        return "không rõ"  # fallback — không chặn luồng chính nếu Weather API lỗi