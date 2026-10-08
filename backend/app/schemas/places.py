from pydantic import BaseModel

class PlacesRequest(BaseModel):
    dish_name: str
    latitude: float
    longitude: float
    radius_m: int = 3000
    limit: int = 20