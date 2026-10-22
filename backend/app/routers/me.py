import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.core.auth import get_required_claims
from app.services.user_service import get_or_create_user, migrate_anonymous_data

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1", tags=["me"])


class MigrateRequest(BaseModel):
    device_id: str


@router.get("/me")
def me(claims: dict = Depends(get_required_claims)):
    try:
        user = get_or_create_user(claims["sub"])
    except Exception:
        logger.exception("Lấy/tạo user thất bại")
        raise HTTPException(status_code=503, detail="Chưa tải được thông tin tài khoản, thử lại sau")

    return {"success": True, "data": {**user, "email": claims.get("email")}}


@router.post("/me/migrate")
def migrate(body: MigrateRequest, claims: dict = Depends(get_required_claims)):
    try:
        user = get_or_create_user(claims["sub"])
        result = migrate_anonymous_data(device_id=body.device_id, user_id=user["id"])
    except Exception:
        logger.exception("Migration dữ liệu thất bại")
        raise HTTPException(status_code=503, detail="Chưa thực hiện chuyển đổi dữ liệu được, thử lại sau")

    return {"success": True, "data": result}