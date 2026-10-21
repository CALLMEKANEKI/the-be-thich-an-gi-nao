from types import SimpleNamespace as NS
from unittest.mock import patch

from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.routers import dishes, spin

# ---------------- Spin ----------------
spin_app = FastAPI()
spin_app.include_router(spin.router)
spin_client = TestClient(spin_app)


def fake_dish(i):
    return NS(id=i, name=f"Món {i}", description=f"Mô tả {i}",
              image_url=f"https://img.test/{i}.jpg", category="món nước", ingredients=None)


def fake_result(n=3):
    return {
        "total": n,
        "recommendations": [
            {"dish": fake_dish(i), "reason": f"Hợp tâm trạng {i}", "confidence": 0.9 - i * 0.01}
            for i in range(1, n + 1)
        ],
    }


def post_spin(body, mood="sadness"):
    with patch.object(spin.emotion_service, "predict_emotion", return_value=mood), \
         patch.object(spin, "recommend_dish", return_value=fake_result()) as recommend:
        response = spin_client.post("/api/v1/spin/recommend", json=body)
    return response, recommend


def test_spin_contract():
    r, recommend = post_spin({"text": "Hôm nay mệt quá, chán ăn ghê"})
    assert r.status_code == 200
    body = r.json()
    assert body["success"] is True
    data = body["data"]
    assert data["detected_mood"] == "sadness"
    assert data["recommendation_id"].startswith("rec_")
    assert data["total"] == len(data["wheel_options"]) == 3
    for option in data["wheel_options"]:
        assert set(option["dish"]) >= {"id", "name", "description", "image_url", "category"}
        assert isinstance(option["reason"], str)
        assert 0 <= option["confidence"] <= 1
    assert recommend.call_args.args[0] == "sadness"   # AI nhận đúng mood do PhoBERT suy ra


def test_spin_accepts_optional_location():
    r, _ = post_spin({"text": "mệt quá", "latitude": 10.7769, "longitude": 106.7009})
    assert r.status_code == 200


def test_spin_requires_text():
    r, _ = post_spin({})
    assert r.status_code == 422


# ---------------- Ingredients ----------------
dishes_app = FastAPI()
dishes_app.include_router(dishes.router)
dishes_client = TestClient(dishes_app)

ITEMS = [{"ingredient": "Thịt bò", "normalized_name": "thit_bo", "quantity": 200, "unit": "g"}]


def test_ingredients_ok():
    with patch.object(dishes, "get_or_generate_ingredients", return_value=ITEMS) as generate:
        r = dishes_client.get("/api/v1/dishes/7/ingredients")
    assert r.status_code == 200
    assert r.json() == {"success": True, "data": {"dish_id": 7, "items": ITEMS}}
    generate.assert_called_once_with(7)


def test_ingredients_unknown_dish_returns_404():
    with patch.object(dishes, "get_or_generate_ingredients", return_value=None):
        assert dishes_client.get("/api/v1/dishes/99999/ingredients").status_code == 404


def test_ingredients_ai_failure_returns_503():
    with patch.object(dishes, "get_or_generate_ingredients", side_effect=RuntimeError("Gemini lỗi")):
        assert dishes_client.get("/api/v1/dishes/1/ingredients").status_code == 503


def test_ingredients_rejects_non_numeric_id():
    assert dishes_client.get("/api/v1/dishes/abc/ingredients").status_code == 422