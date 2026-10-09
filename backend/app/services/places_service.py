from concurrent.futures import ThreadPoolExecutor
from math import asin, cos, radians, sin, sqrt
import httpx
from app.core.config import settings

GOONG_URL = "https://rsapi.goong.io"
GEOAPIFY_URL = "https://api.geoapify.com/v2/places"
GOONG_MAX_RESULTS = 8
GOONG_FOOD_TYPES = {"restaurant", "food", "cafe", "meal_takeaway", "bakery"}


def _haversine_m(lat1, lon1, lat2, lon2) -> int:
    """Khoảng cách đường chim bay (mét) giữa 2 toạ độ."""
    r = 6371000
    p1, p2 = radians(lat1), radians(lat2)
    a = sin((p2 - p1) / 2) ** 2 + cos(p1) * cos(p2) * sin(radians(lon2 - lon1) / 2) ** 2
    return int(2 * r * asin(sqrt(a)))


def _goong_detail(place_id: str) -> dict:
    """Gọi Detail API lấy tọa độ & thông tin chi tiết địa điểm."""
    try:
        r = httpx.get(
            f"{GOONG_URL}/Place/Detail",
            params={"place_id": place_id, "api_key": settings.goong_api_key},
            timeout=10.0,
        )
        return r.json().get("result", {}) if r.status_code == 200 else {}
    except Exception:
        return {}


def _goong_search(keyword, latitude, longitude, radius_m, limit):
    max_results = min(limit, GOONG_MAX_RESULTS)
    ac = httpx.get(
        f"{GOONG_URL}/Place/AutoComplete",
        params={
            "input": keyword,
            "location": f"{latitude},{longitude}",
            "radius": max(radius_m / 1000, 1),  # Goong tính bằng km
            "limit": max_results,
            "api_key": settings.goong_api_key,
        },
        timeout=10.0,
    )
    ac.raise_for_status()
    predictions = ac.json().get("predictions", [])

    # Lọc danh sách ứng viên là dịch vụ ăn uống
    candidates = []
    for pred in predictions:
        types = pred.get("types") or []
        if types and not GOONG_FOOD_TYPES.intersection(types):
            continue  # Bỏ qua địa danh, tên đường...
        if pred.get("place_id"):
            candidates.append(pred)

    if not candidates:
        return []

    # Gọi song song (Multithreading) Detail API cho tất cả các candidates cùng lúc
    with ThreadPoolExecutor(max_workers=min(len(candidates), 8)) as pool:
        place_ids = [p["place_id"] for p in candidates]
        details = list(pool.map(_goong_detail, place_ids))

    places = []
    for pred, result in zip(candidates, details):
        if not result:
            continue

        loc = result.get("geometry", {}).get("location", {})
        lat, lng = loc.get("lat"), loc.get("lng")
        if lat is None or lng is None:
            continue

        distance_m = _haversine_m(latitude, longitude, lat, lng)
        if distance_m > radius_m:
            continue  # Lọc lại chuẩn bán kính thực tế

        sf = pred.get("structured_formatting", {})
        places.append({
            "name": result.get("name") or sf.get("main_text", ""),
            "address": sf.get("secondary_text") or result.get("formatted_address", ""),
            "latitude": lat,
            "longitude": lng,
            "rating": 0.0,
            "distance_m": distance_m,
            "map_url": f"https://www.google.com/maps/search/?api=1&query={lat},{lng}",
        })

    places.sort(key=lambda p: p["distance_m"])
    return places


# ---------------- Geoapify (dự phòng) ----------------
def _geoapify_query(latitude, longitude, radius_m, limit, name=None):
    params = {
        "categories": "catering.restaurant,catering.fast_food,catering.cafe",
        "filter": f"circle:{longitude},{latitude},{radius_m}",  # lon,lat
        "bias": f"proximity:{longitude},{latitude}",
        "limit": limit,
        "apiKey": settings.geoapify_api_key,
    }
    if name:
        params["name"] = name
    response = httpx.get(GEOAPIFY_URL, params=params, timeout=10.0)
    response.raise_for_status()
    return response.json().get("features", [])


def _geoapify_to_place(feature):
    props = feature.get("properties", {})
    lon, lat = feature.get("geometry", {}).get("coordinates", [None, None])
    return {
        "name": props.get("name", ""),
        "address": props.get("formatted") or props.get("address_line2", ""),
        "latitude": lat,
        "longitude": lon,
        "rating": 0.0,
        "distance_m": props.get("distance", 0),
        "map_url": f"https://www.google.com/maps/search/?api=1&query={lat},{lon}",
    }


def _geoapify_search(dish_name, latitude, longitude, radius_m, limit):
    keywords = [dish_name]
    words = dish_name.split()
    if len(words) > 1:
        keywords.append(words[0])

    features = []
    for kw in keywords:
        features = _geoapify_query(latitude, longitude, radius_m, limit, name=kw)
        if features:
            break
    if not features:
        features = _geoapify_query(latitude, longitude, radius_m, limit)

    return [_geoapify_to_place(f) for f in features if f.get("properties", {}).get("name")]


# ---------------- Điểm vào ----------------
def search_nearby_places(dish_name, latitude, longitude, radius_m, limit):
    if settings.map_provider == "goong":
        keywords = [dish_name]
        words = dish_name.split()
        if len(words) > 1:
            keywords.append(words[0])

        for kw in keywords:
            try:
                places = _goong_search(kw, latitude, longitude, radius_m, limit)
            except httpx.HTTPError:
                break  # Lỗi Goong API -> Tự động fallback sang Geoapify
            if places:
                return places

    return _geoapify_search(dish_name, latitude, longitude, radius_m, limit)