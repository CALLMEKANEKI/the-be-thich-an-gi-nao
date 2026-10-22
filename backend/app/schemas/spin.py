from pydantic import BaseModel, Field

class SpinRequest(BaseModel):
    text: str
    latitude: float | None = None
    longitude: float | None = None
    
class SelectRequest(BaseModel):
    dish_id: int
    mood: str | None = Field(default=None, max_length=50)