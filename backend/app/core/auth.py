import jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import PyJWKClient

from app.core.config import settings

bearer = HTTPBearer(auto_error=False)
ASYMMETRIC_ALGS = ["RS256", "ES256"]
_jwks_client: PyJWKClient | None = None


def _issuer() -> str:
    if not settings.supabase_url:
        raise RuntimeError("SUPABASE_URL chưa được cấu hình")
    return f"{settings.supabase_url.rstrip('/')}/auth/v1"


def _signing_key(token: str):
    global _jwks_client
    if _jwks_client is None:
        _jwks_client = PyJWKClient(f"{_issuer()}/.well-known/jwks.json", cache_keys=True)
    return _jwks_client.get_signing_key_from_jwt(token).key


def verify_token(token: str) -> dict:
    """Trả về claims nếu token hợp lệ, ngược lại raise jwt.PyJWTError."""
    alg = jwt.get_unverified_header(token).get("alg")
    common = dict(audience="authenticated", issuer=_issuer(), options={"require": ["exp", "sub"]})
    if alg in ASYMMETRIC_ALGS:
        return jwt.decode(token, _signing_key(token), algorithms=ASYMMETRIC_ALGS, **common)
    if alg == "HS256" and settings.supabase_jwt_secret:
        return jwt.decode(token, settings.supabase_jwt_secret, algorithms=["HS256"], **common)
    raise jwt.InvalidAlgorithmError(f"Thuật toán không được hỗ trợ: {alg}")


def get_optional_claims(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
) -> dict | None:
    """Không có token thì là khách (None). Có token mà sai thì 401."""
    if credentials is None:
        return None
    try:
        return verify_token(credentials.credentials)
    except jwt.PyJWKClientConnectionError:
        raise HTTPException(status_code=503, detail="Không kiểm tra được đăng nhập, thử lại sau")
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Token không hợp lệ hoặc đã hết hạn",
                            headers={"WWW-Authenticate": "Bearer"})


def get_required_claims(claims: dict | None = Depends(get_optional_claims)) -> dict:
    if claims is None:
        raise HTTPException(status_code=401, detail="Cần đăng nhập",
                            headers={"WWW-Authenticate": "Bearer"})
    return claims