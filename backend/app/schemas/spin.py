from pydantic import BaseModel

class SpinRequest(BaseModel):
    text: str
    latitude: float | None = None
    longitude: float | None = None