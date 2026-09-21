from fastapi import APIRouter

router = APIRouter(prefix="/api/v1/places", tags=["place"])

@router.post("/nearly")
def nearly(payload: dict):
    return {
        "success": True,
        "data": [{
            "place_id": "place_001",
            "name": "Phở_Anh_Hai",
            "address": "Số 12 Đan Phượng",
            "latitude": 10.7771,
            "longitude": 106.7012,
            "distance_m": 167,
            "rating": 4.5,
            "opening_status": "OPEN",
            "map_url": "http://maps.exsample.com/place_001"
        }]
    }
