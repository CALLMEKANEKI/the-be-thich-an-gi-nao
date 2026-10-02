from pydantic import BaseModel

class SpinRequest(BaseModel):
    text: str  