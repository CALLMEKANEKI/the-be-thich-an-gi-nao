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
    
from pydantic import BaseModel, Field


class CartIngredient(BaseModel):
    name: str
    normalized_name: str | None = None  # thiếu thì backend tự tính từ name
    quantity: float = Field(gt=0)
    unit: str


class CartDish(BaseModel):
    id: int | str
    name: str


class CartLocation(BaseModel):
    latitude: float
    longitude: float


class CartRequest(BaseModel):
    request_id: str | None = None
    user_id: str | None = None
    dish: CartDish
    ingredients: list[CartIngredient] = Field(min_length=1)
    location: CartLocation | None = None


class CartItem(BaseModel):
    ingredient: str
    normalized_name: str
    quantity: float
    unit: str
    available: bool
    sku: str | None = None
    product_name: str | None = None
    pack_size: float | None = None
    packs_needed: int | None = None
    price_vnd: int | None = None
    subtotal_vnd: int | None = None
    search_url: str | None = None
    note: str | None = None


class CartSummary(BaseModel):
    total: int
    available: int
    unavailable: int
    estimated_total_vnd: int


class CartData(BaseModel):
    request_id: str
    status: str
    summary: CartSummary
    items: list[CartItem]
    notion_page_id: str | None = None


class CartResponse(BaseModel):
    success: bool = True
    data: CartData