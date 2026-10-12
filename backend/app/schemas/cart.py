from enum import Enum
from pydantic import BaseModel

class Unit(str, Enum):
    g = "g"
    ml = "ml"
    qua = "quả"
    cu = "củ"
    tep = "tép"
    con = "con"
    mieng = "miếng"
    bo = "bó"

class IngredientIn(BaseModel):
    name: str
    quantity: float
    unit: Unit

class IngredientListIn(BaseModel):
    items: list[IngredientIn]