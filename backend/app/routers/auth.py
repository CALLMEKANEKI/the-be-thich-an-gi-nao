import logging
import time
import uuid
import jwt
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel

from app.core.config import settings
from app.services.user_service import get_or_create_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


class AuthRequest(BaseModel):
    email: str
    password: str
    name: str | None = None


def _get_issuer() -> str:
    url = settings.supabase_url or "https://supabase.co"
    return f"{url.rstrip('/')}/auth/v1"


def _create_jwt_token(auth_user_id: str, email: str, name: str | None = None) -> str:
    secret = settings.supabase_jwt_secret or "the-be-thich-an-gi-nao-secret-jwt-key-2026-auth"
    claims = {
        "sub": auth_user_id,
        "aud": "authenticated",
        "iss": _get_issuer(),
        "exp": int(time.time()) + (30 * 86400),  # 30 ngày
        "email": email,
        "user_metadata": {
            "name": name or email.split("@")[0],
        },
    }
    return jwt.encode(claims, secret, algorithm="HS256")


@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(body: AuthRequest):
    email = body.email.strip().lower()
    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Email không hợp lệ")
    if len(body.password) < 6:
        raise HTTPException(status_code=400, detail="Mật khẩu phải có tối thiểu 6 ký tự")

    # Tạo auth_user_id xác định theo email
    auth_user_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, email))
    name = body.name.strip() if body.name else email.split("@")[0]

    try:
        user = get_or_create_user(auth_user_id)
    except Exception as e:
        logger.exception("Lỗi khi tạo user trong DB")
        raise HTTPException(status_code=500, detail="Không thể khởi tạo tài khoản, vui lòng thử lại sau")

    token = _create_jwt_token(auth_user_id, email, name)

    return {
        "success": True,
        "message": "Đăng ký tài khoản thành công!",
        "access_token": token,
        "token_type": "bearer",
        "data": {
            "id": user["id"],
            "auth_user_id": auth_user_id,
            "email": email,
            "name": name,
        },
    }


@router.post("/login")
def login(body: AuthRequest):
    email = body.email.strip().lower()
    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Email không hợp lệ")
    if not body.password:
        raise HTTPException(status_code=400, detail="Vui lòng nhập mật khẩu")

    auth_user_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, email))
    name = body.name.strip() if body.name else email.split("@")[0]

    try:
        user = get_or_create_user(auth_user_id)
    except Exception as e:
        logger.exception("Lỗi khi tìm/tạo user trong DB")
        raise HTTPException(status_code=500, detail="Lỗi hệ thống, vui lòng thử lại sau")

    token = _create_jwt_token(auth_user_id, email, name)

    return {
        "success": True,
        "message": "Đăng nhập thành công!",
        "access_token": token,
        "token_type": "bearer",
        "data": {
            "id": user["id"],
            "auth_user_id": auth_user_id,
            "email": email,
            "name": name,
        },
    }
