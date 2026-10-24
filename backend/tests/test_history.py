from types import SimpleNamespace as NS
from unittest.mock import patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.core import auth
from app.routers import spin

SUB = "11111111-1111-1111-1111-111111111111"

app = FastAPI()
app.include_router(spin.router)
client = TestClient(app)


@pytest.fixture
def as_user(monkeypatch):
    # override get_optional_claims cũng áp dụng cho get_required_claims (cùng phụ thuộc)
    monkeypatch.setitem(app.dependency_overrides, auth.get_optional_claims, lambda: {"sub": SUB})


# ---------------- select ----------------
def test_select_as_guest_is_not_recorded():
    with patch.object(spin.history_service, "record_selection") as record:
        r = client.post("/api/v1/spin/select", json={"dish_id": 1, "mood": "sadness"})
    assert r.status_code == 200
    assert r.json() == {"success": True, "data": {"recorded": False}}
    record.assert_not_called()


def test_select_as_user_is_recorded(as_user):
    with patch.object(spin.history_service, "record_selection", return_value=True) as record:
        r = client.post("/api/v1/spin/select", json={"dish_id": 7, "mood": "sadness"})
    assert r.json() == {"success": True, "data": {"recorded": True}}
    record.assert_called_once_with(SUB, 7, "sadness")


def test_select_unknown_dish_is_404(as_user):
    with patch.object(spin.history_service, "record_selection", return_value=False):
        assert client.post("/api/v1/spin/select", json={"dish_id": 999}).status_code == 404


def test_select_db_failure_is_503(as_user):
    with patch.object(spin.history_service, "record_selection", side_effect=RuntimeError("DB lỗi")):
        assert client.post("/api/v1/spin/select", json={"dish_id": 1}).status_code == 503


def test_select_requires_dish_id(as_user):
    assert client.post("/api/v1/spin/select", json={"mood": "x"}).status_code == 422


# ---------------- history ----------------
def test_history_requires_login():
    assert client.get("/api/v1/spin/history").status_code == 401


def test_history_ok_and_paging(as_user):
    items = [{"id": 1, "mood": "sadness", "created_at": "2026-10-21T10:00:00",
              "dish": {"id": 7, "name": "Phở bò", "description": "", "image_url": "", "category": "món nước"}}]
    with patch.object(spin.history_service, "list_history", return_value=(1, items)) as lister:
        r = client.get("/api/v1/spin/history", params={"limit": 5, "offset": 10})
    assert r.json() == {"success": True, "data": {"total": 1, "limit": 5, "offset": 10, "items": items}}
    lister.assert_called_once_with(SUB, 5, 10)


@pytest.mark.parametrize("params", [{"limit": 0}, {"limit": 101}, {"offset": -1}])
def test_history_rejects_bad_paging(as_user, params):
    assert client.get("/api/v1/spin/history", params=params).status_code == 422


# ---------------- recommend dùng lịch sử ----------------
RESULT = {"total": 1, "recommendations": [
    {"dish": NS(id=1, name="Món 1", description="d", image_url="", category="c", ingredients=None),
     "reason": "r", "confidence": 0.9}]}


def post_recommend():
    with patch.object(spin.emotion_service, "predict_emotion", return_value="sadness"), \
         patch.object(spin, "recommend_dish", return_value=RESULT) as recommend:
        r = client.post("/api/v1/spin/recommend", json={"text": "mệt quá"})
    return r, recommend


def test_recommend_passes_recent_names_for_user(as_user):
    with patch.object(spin.history_service, "recent_dish_names", return_value=["Phở bò"]):
        r, recommend = post_recommend()
    assert r.status_code == 200
    assert recommend.call_args.kwargs["recent_names"] == ["Phở bò"]


def test_recommend_guest_gets_no_history():
    with patch.object(spin.history_service, "recent_dish_names") as recent:
        r, recommend = post_recommend()
    assert r.status_code == 200
    assert recommend.call_args.kwargs["recent_names"] == []
    recent.assert_not_called()


def test_recommend_survives_history_failure(as_user):
    with patch.object(spin.history_service, "recent_dish_names", side_effect=RuntimeError("DB lỗi")):
        r, recommend = post_recommend()
    assert r.status_code == 200
    assert recommend.call_args.kwargs["recent_names"] == []