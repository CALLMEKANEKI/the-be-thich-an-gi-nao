from fastapi import APIRouter
from app.schemas.places import PlacesRequest
from app.services.places_service import search_nearby_places

router = APIRouter(prefix="/api/v1/places", tags=["places"])

@router.post("/nearby")
def nearby(payload: PlacesRequest):
    places = search_nearby_places(
        payload.dish_name, payload.latitude, payload.longitude,
        payload.radius_m, payload.limit
    )
    return {"success": True, "data": places}