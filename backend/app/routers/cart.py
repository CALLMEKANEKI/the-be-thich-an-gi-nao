import uuid

from fastapi import APIRouter

from app.schemas.cart import CartData, CartRequest, CartResponse
from app.services.sku_service import build_cart

router = APIRouter(prefix="/api/v1", tags=["cart"])


@router.post("/cart", response_model=CartResponse)
def create_cart(payload: CartRequest):
    items, summary = build_cart(payload.ingredients)

    # TODO (task n8n Webhook Workflow): gửi `items` + `payload.dish` sang n8n
    # (N8N_BHX_WEBHOOK_URL), nhận notion_page_id. Bọc try/except: n8n lỗi
    # thì vẫn trả kết quả map, notion_page_id = None.

    return CartResponse(
        data=CartData(
            request_id=payload.request_id or f"req_{uuid.uuid4().hex[:8]}",
            status="processed",
            summary=summary,
            items=items,
            notion_page_id=None,
        )
    )