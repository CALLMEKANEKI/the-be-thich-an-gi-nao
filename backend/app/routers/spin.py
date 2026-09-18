from fastapi import APIRouter

router = APIRouter(prefix="/api/v1/spin", tags=["spin"])

@router.post("/recommend")
def recommend(payload: dict):
    return{
        "success": True,
        "data":{
            "recommendation_id": "rec_stub_001",
            "dish": {
                "id": "dish_001",
                "name": "Phở Bò",
                "desciption": "Món nước nóng với bánh phở, thịt bò.",
                "image_url": "https://example.com/pho=bo.jpg",
                "category": "vietnamese",
            },
            "reason": "Stub respose để test contact",
            "confidence": 0.87,
            "ingredients": [{"name": "Bánh phở", "quantity": 500, "unit": "g"}],
            "available_model": ["restaurant", "cook"]
        }
    }