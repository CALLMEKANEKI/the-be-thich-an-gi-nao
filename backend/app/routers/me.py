import logging

from fastapi import APIRouter, Depends, HTTPException

from app.core.auth import get_required_claims
from app.services.user_service import get_or_create_user

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1", tags=["me"])


@router.get("/me")
def me(claims: dict = Depends(get_required_claims)):
    try:
        user = get_or_create_user(claims["sub"])
    except Exception:
        logger.exception("Lấy/tạo user thất bại")
        raise HTTPException(status_code=503, detail="Chưa tải được thông tin tài khoản, thử lại sau")
    return {"success": True, "data": {**user, "email": claims.get("email")}}