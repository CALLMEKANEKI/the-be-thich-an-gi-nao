import httpx
from app.core.config import settings

PLACES_URL = "https://api.geoapify.com/v2/places"


def _query_places(latitude, longitude, radius_m, limit, name=None):
    params = {
        "categories": "catering.restaurant,catering.fast_food",
        "filter": f"circle:{longitude},{latitude},{radius_m}",  # lon,lat — ngược với schema
        "bias": f"proximity:{longitude},{latitude}",
        "limit": limit,
        "apiKey": settings.map_api_key,
    }
    if name:
        params["name"] = name
    response = httpx.get(PLACES_URL, params=params, timeout=10.0)
    response.raise_for_status()
    return response.json().get("features", [])


def _to_place(feature):
    props = feature.get("properties", {})
    lon, lat = feature.get("geometry", {}).get("coordinates", [None, None])
    return {
        "name": props.get("name", ""),
        "address": props.get("formatted") or props.get("address_line2", ""),
        "latitude": lat,
        "longitude": lon,
        "rating": 0.0,  # dữ liệu OSM không có rating
        "distance_m": props.get("distance", 0),
        "map_url": f"https://www.google.com/maps/search/?api=1&query={lat},{lon}",
    }


def search_nearby_places(dish_name, latitude, longitude, radius_m, limit):
    keywords = [dish_name]
    words = dish_name.split()
    if len(words) > 1:
        keywords.append(words[0])  # "Phở Bò" -> "Phở"

    features = []
    for kw in keywords:
        features = _query_places(latitude, longitude, radius_m, limit, name=kw)
        if features:
            break
    if not features:
        features = _query_places(latitude, longitude, radius_m, limit)

    return [_to_place(f) for f in features if f.get("properties", {}).get("name")]