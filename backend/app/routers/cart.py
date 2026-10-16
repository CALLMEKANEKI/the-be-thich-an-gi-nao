import uuid

from fastapi import APIRouter

from app.schemas.cart import CartData, CartRequest, CartResponse
from app.services.sku_service import build_cart
from app.services.n8n import sync_to_n8n

router = APIRouter(prefix="/api/v1", tags=["cart"])


@router.post("/cart", response_model=CartResponse)
def create_cart(payload: CartRequest):
    items, summary = build_cart(payload.ingredients)

    n8n_result = sync_to_n8n({
        "request_id": payload.request_id,
        "user_id": payload.user_id,
        "dish": payload.dish.model_dump(),
        "summary": summary.model_dump(),
        "items": [i.model_dump() for i in items],
    })
    notion_page_id = (n8n_result or {}).get("notion_page_id")
    request_id = payload.request_id or f"req_{uuid.uuid4().hex[:8]}"
    return CartResponse(
        data=CartData(
            request_id=request_id,
            status="processed",
            summary=summary,
            items=items,
            notion_page_id=notion_page_id,
        )
    )