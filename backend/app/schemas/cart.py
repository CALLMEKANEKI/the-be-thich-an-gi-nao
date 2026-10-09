from pydantic import BaseModel

class IngredientIn(BaseModel):
    name: str
    quantity: float
    unit: str

class IngredientOut(BaseModel):
    ingredient: str
    normalized_name: str
    quantity: float
    unit: str

class IngredientListIn(BaseModel):
    items: list[IngredientIn]