from unittest.mock import patch

import httpx
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.core.config import settings
from app.routers import places
from app.services import places_service as ps
from tests.helpers import FakeResponse

USER = (10.7769, 106.7009)                       # quận 1, TP.HCM
VIEN_QUOC_KY = (10.772545707, 106.704509995)     # cách USER khoảng 624 m
CAM_LOAN = (10.759436053, 106.706908289)         # khoảng 2049 m
FAR_AWAY = (10.90, 106.90)                       # khoảng 25 km


def prediction(place_id, name, types=("restaurant",)):
    return {
        "place_id": place_id,
        "types": list(types),
        "structured_formatting": {"main_text": name, "secondary_text": f"Địa chỉ của {name}"},
    }


def detail(name, lat, lng):
    return {"result": {"name": name, 
                        "formatted_address": f"{name}, ...",
                        "geometry": {"location": {"lat": lat, "lng": lng}}}}


def make_fake_get(predictions=None, details=None, features=None, goong_error=False, calls=None):
    """Giả lập httpx.get cho Goong và Geoapify. `calls` ghi lại (url, params) mỗi lần gọi."""
    def fake_get(url, params=None, timeout=None, **kwargs):
        if calls is not None:
            calls.append((url, params))
        if "goong" in url:
            if goong_error:
                raise httpx.ConnectError("lỗi mạng giả lập")
            if url.endswith("/Place/AutoComplete"):
                preds = predictions(params["input"]) if callable(predictions) else (predictions or [])
                return FakeResponse({"predictions": preds})
            if url.endswith("/Place/Detail"):
                return FakeResponse(details[params["place_id"]])
        if "geoapify" in url:
            return FakeResponse({"features": features or []})
        raise AssertionError(f"URL ngoài dự kiến: {url}")
    return fake_get


@pytest.fixture(autouse=True)
def goong_provider(monkeypatch):
    monkeypatch.setattr(settings, "map_provider", "goong")


def test_haversine_known_distance():
    assert ps._haversine_m(*USER, *USER) == 0
    assert abs(ps._haversine_m(*USER, *VIEN_QUOC_KY) - 624) <= 3


def test_goong_filters_sorts_and_formats(monkeypatch):
    predictions = [
        prediction("p_cam_loan", "Phở bò Cầm Loan"),
        prediction("p_vqk", "Phở Bò Viên Quốc Ký"),
        prediction("p_street", "Đường Phở", types=("route",)),
        prediction("p_far", "Quán ở xa"),
    ]
    details = {
        "p_cam_loan": detail("Phở bò Cầm Loan", *CAM_LOAN),
        "p_vqk": detail("Phở Bò Viên Quốc Ký", *VIEN_QUOC_KY),
        "p_street": detail("Đường Phở", *USER),
        "p_far": detail("Quán ở xa", *FAR_AWAY),
    }
    monkeypatch.setattr(ps.httpx, "get", make_fake_get(predictions, details))

    found = ps._goong_search("phở bò", *USER, 3000, 20)

    # gần trước xa sau; bỏ tên đường (types=route) và quán nằm ngoài bán kính
    assert [p["name"] for p in found] == ["Phở Bò Viên Quốc Ký", "Phở bò Cầm Loan"]
    first = found[0]
    assert first["address"] == "Địa chỉ của Phở Bò Viên Quốc Ký"
    assert first["rating"] == 0.0
    assert first["map_url"] == (
        f"https://www.google.com/maps/search/?api=1&query={first['latitude']},{first['longitude']}"
    )
    assert first["distance_m"] < found[1]["distance_m"] <= 3000


def test_goong_limits_detail_calls(monkeypatch):
    predictions = [prediction(f"p{i}", f"Quán {i}") for i in range(12)]
    details = {f"p{i}": detail(f"Quán {i}", USER[0] + i * 0.0001, USER[1]) for i in range(12)}
    calls = []
    monkeypatch.setattr(ps.httpx, "get", make_fake_get(predictions, details, calls=calls))

    found = ps._goong_search("phở", *USER, 3000, 20)

    detail_calls = [c for c in calls if c[0].endswith("/Place/Detail")]
    assert len(detail_calls) == ps.GOONG_MAX_RESULTS
    assert len(found) == ps.GOONG_MAX_RESULTS


@pytest.mark.parametrize("radius_m, expected_km", [(3000, 3), (500, 1)])
def test_goong_radius_is_sent_in_km(monkeypatch, radius_m, expected_km):
    calls = []
    monkeypatch.setattr(ps.httpx, "get", make_fake_get([], {}, calls=calls))
    ps._goong_search("phở", *USER, radius_m, 20)
    assert calls[0][1]["radius"] == expected_km


def test_search_retries_with_first_word(monkeypatch):
    def predictions(keyword):
        return [prediction("p1", "Phở Hòa")] if keyword == "Phở" else []

    details = {"p1": detail("Phở Hòa", *VIEN_QUOC_KY)}
    calls = []
    monkeypatch.setattr(ps.httpx, "get", make_fake_get(predictions, details, calls=calls))

    found = ps.search_nearby_places("Phở Bò", *USER, 3000, 20)

    inputs = [c[1]["input"] for c in calls if c[0].endswith("/Place/AutoComplete")]
    assert inputs == ["Phở Bò", "Phở"]
    assert [p["name"] for p in found] == ["Phở Hòa"]


def test_falls_back_to_geoapify_when_goong_fails(monkeypatch):
    features = [
        {"properties": {"name": "Quán A", "formatted": "Địa chỉ A", "distance": 120},
         "geometry": {"coordinates": [106.70, 10.77]}},
        {"properties": {"formatted": "Không có tên"}, "geometry": {"coordinates": [106.70, 10.77]}},
    ]
    calls = []
    monkeypatch.setattr(ps.httpx, "get", make_fake_get(features=features, goong_error=True, calls=calls))

    found = ps.search_nearby_places("Phở Bò", *USER, 3000, 20)

    assert [p["name"] for p in found] == ["Quán A"]                               # bỏ dòng không có tên
    assert found[0]["distance_m"] == 120
    assert (found[0]["latitude"], found[0]["longitude"]) == (10.77, 106.70)       # coordinates là [lon, lat]
    geo_params = next(p for u, p in calls if "geoapify" in u)
    assert geo_params["filter"] == "circle:106.7009,10.7769,3000"                 # thứ tự lon,lat


def test_geoapify_provider_never_calls_goong(monkeypatch):
    monkeypatch.setattr(settings, "map_provider", "geoapify")
    calls = []
    monkeypatch.setattr(ps.httpx, "get", make_fake_get(features=[], calls=calls))

    ps.search_nearby_places("Phở Bò", *USER, 3000, 20)

    assert calls and all("geoapify" in url for url, _ in calls)


# ---- Router ----
app = FastAPI()
app.include_router(places.router)
client = TestClient(app)


def test_places_endpoint_shape_and_defaults():
    found = [{"name": "Phở 24", "address": "Q1", "latitude": 10.7, "longitude": 106.7,
              "rating": 0.0, "distance_m": 100,
              "map_url": "https://www.google.com/maps/search/?api=1&query=10.7,106.7"}]
    with patch.object(places, "search_nearby_places", return_value=found) as search:
        r = client.post("/api/v1/places/nearby",
                        json={"dish_name": "Phở Bò", "latitude": 10.7769, "longitude": 106.7009})
    assert r.status_code == 200
    assert r.json() == {"success": True, "data": found}
    search.assert_called_once_with("Phở Bò", 10.7769, 106.7009, 3000, 20)  # radius_m, limit mặc định


def test_places_endpoint_requires_location():
    r = client.post("/api/v1/places/nearby", json={"dish_name": "Phở Bò"})
    assert r.status_code == 422