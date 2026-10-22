import time
from unittest.mock import patch

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient

from app.core import auth
from app.core.config import settings
from app.routers import me

ISSUER = "https://test.supabase.co/auth/v1"
SUB = "11111111-1111-1111-1111-111111111111"
SECRET = "s" * 40


@pytest.fixture(autouse=True)
def config(monkeypatch):
    monkeypatch.setattr(settings, "supabase_url", "https://test.supabase.co")
    monkeypatch.setattr(settings, "supabase_jwt_secret", "")


@pytest.fixture(scope="module")
def key():
    return rsa.generate_private_key(public_exponent=65537, key_size=2048)


@pytest.fixture(autouse=True)
def jwks(monkeypatch, key):
    monkeypatch.setattr(auth, "_signing_key", lambda token: key.public_key())


def token(key, alg="RS256", **overrides):
    claims = {"sub": SUB, "aud": "authenticated", "iss": ISSUER,
              "exp": int(time.time()) + 3600, "email": "a@b.c"}
    claims.update(overrides)
    claims = {k: v for k, v in claims.items() if v is not None}
    return jwt.encode(claims, key, algorithm=alg, headers={"kid": "k1"})


# ---------------- verify_token ----------------
def test_valid_token(key):
    assert auth.verify_token(token(key))["sub"] == SUB


@pytest.mark.parametrize("overrides, error", [
    ({"exp": int(time.time()) - 10}, jwt.ExpiredSignatureError),
    ({"aud": "anon"}, jwt.InvalidAudienceError),
    ({"iss": "https://evil.example/auth/v1"}, jwt.InvalidIssuerError),
    ({"exp": None}, jwt.MissingRequiredClaimError),
    ({"sub": None}, jwt.MissingRequiredClaimError),
])
def test_bad_claims_rejected(key, overrides, error):
    with pytest.raises(error):
        auth.verify_token(token(key, **overrides))


def test_token_signed_by_other_key_rejected(key):
    other = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    with pytest.raises(jwt.InvalidSignatureError):
        auth.verify_token(token(other))


def test_alg_none_rejected():
    forged = jwt.encode({"sub": SUB, "aud": "authenticated", "iss": ISSUER,
                         "exp": int(time.time()) + 3600}, None, algorithm="none")
    with pytest.raises(jwt.InvalidAlgorithmError):
        auth.verify_token(forged)


def test_hs256_only_when_secret_is_configured(monkeypatch):
    hs = token(SECRET, alg="HS256")
    with pytest.raises(jwt.InvalidAlgorithmError):          # chưa cấu hình secret
        auth.verify_token(hs)
    monkeypatch.setattr(settings, "supabase_jwt_secret", SECRET)
    assert auth.verify_token(hs)["sub"] == SUB
    with pytest.raises(jwt.InvalidSignatureError):          # sai secret
        auth.verify_token(token("x" * 40, alg="HS256"))


# ---------------- dependencies ----------------
app = FastAPI()


@app.get("/optional")
def optional(claims=Depends(auth.get_optional_claims)):
    return {"sub": claims["sub"] if claims else None}


@app.get("/required")
def required(claims=Depends(auth.get_required_claims)):
    return {"sub": claims["sub"]}


client = TestClient(app)


def bearer(t):
    return {"Authorization": f"Bearer {t}"}


def test_guest_allowed_on_optional_but_not_required():
    assert client.get("/optional").json() == {"sub": None}
    assert client.get("/required").status_code == 401


def test_valid_token_accepted_everywhere(key):
    assert client.get("/optional", headers=bearer(token(key))).json() == {"sub": SUB}
    assert client.get("/required", headers=bearer(token(key))).json() == {"sub": SUB}


@pytest.mark.parametrize("bad", ["garbage", "a.b.c"])
def test_invalid_token_is_401_even_on_optional(bad):
    assert client.get("/optional", headers=bearer(bad)).status_code == 401
    assert client.get("/required", headers=bearer(bad)).status_code == 401


def test_expired_token_is_401(key):
    assert client.get("/optional", headers=bearer(token(key, exp=int(time.time()) - 10))).status_code == 401


def test_jwks_outage_is_503_not_401(monkeypatch, key):
    def boom(_token):
        raise jwt.PyJWKClientConnectionError("không kết nối được")
    monkeypatch.setattr(auth, "_signing_key", boom)
    assert client.get("/optional", headers=bearer(token(key))).status_code == 503


# ---------------- /me & Migration ----------------
me_app = FastAPI()
me_app.include_router(me.router)
me_app.dependency_overrides[auth.get_required_claims] = lambda: {"sub": SUB, "email": "a@b.c"}
me_client = TestClient(me_app)


def test_me_returns_internal_user():
    with patch.object(me, "get_or_create_user", return_value={"id": 7, "auth_user_id": SUB}) as get_user:
        r = me_client.get("/api/v1/me")
    assert r.status_code == 200
    assert r.json() == {"success": True, "data": {"id": 7, "auth_user_id": SUB, "email": "a@b.c"}}
    get_user.assert_called_once_with(SUB)


def test_anonymous_data_migration_endpoint():
    """Kiểm tra endpoint POST /api/v1/me/migrate."""
    mock_device_id = "test-device-uuid-1234"
    mock_user_id = 7

    with patch.object(me, "get_or_create_user", return_value={"id": mock_user_id, "auth_user_id": SUB}), \
         patch.object(me, "migrate_anonymous_data", return_value={"spin_history": 2, "shopping_lists": 1}) as mock_migrate:
        
        response = me_client.post(
            "/api/v1/me/migrate",
            json={"device_id": mock_device_id}
        )
        
        assert response.status_code == 200
        assert response.json()["success"] is True
        assert response.json()["data"] == {"spin_history": 2, "shopping_lists": 1}
        mock_migrate.assert_called_once_with(device_id=mock_device_id, user_id=mock_user_id)