from unittest.mock import patch

from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.routers import cart
from app.services.sku_service import get_catalog

app = FastAPI()
app.include_router(cart.router)
client = TestClient(app)


def post_cart(ingredients, **extra):
    body = {"dish": {"id": "dish-001", "name": "Món thử"}, "ingredients": ingredients, **extra}
    with patch("app.routers.cart.sync_to_n8n", return_value=None):
        return client.post("/api/v1/cart", json=body)


def first_item(response):
    return response.json()["data"]["items"][0]


def test_available_item_matches_catalog():
    product = get_catalog()[("ca_chua", "quả")]
    r = post_cart([{"name": "Cà chua", "quantity": 2, "unit": "quả"}])
    assert r.status_code == 200
    item = first_item(r)
    assert item["available"] is True
    assert item["normalized_name"] == "ca_chua"   # tự tính khi request không gửi
    assert item["sku"] == product.sku
    assert item["packs_needed"] == 1
    assert item["subtotal_vnd"] == product.price_vnd


def test_packs_needed_rounds_up():
    product = get_catalog()[("ca_chua", "quả")]
    exact = first_item(post_cart([{"name": "Cà chua", "quantity": product.pack_size, "unit": "quả"}]))
    over = first_item(post_cart([{"name": "Cà chua", "quantity": product.pack_size + 1, "unit": "quả"}]))
    assert exact["packs_needed"] == 1
    assert over["packs_needed"] == 2
    assert over["subtotal_vnd"] == 2 * product.price_vnd


def test_unknown_ingredient_is_unavailable():
    item = first_item(post_cart([{"name": "Nguyên liệu không có", "quantity": 1, "unit": "g"}]))
    assert item["available"] is False
    assert item["sku"] is None and item["search_url"] is None
    assert item["note"] == "Chưa tìm thấy trên Bách Hoá Xanh"


def test_summary_matches_items():
    r = post_cart([
        {"name": "Cà chua", "quantity": 2, "unit": "quả"},
        {"name": "Nguyên liệu không có", "quantity": 1, "unit": "g"},
    ])
    data = r.json()["data"]
    items, s = data["items"], data["summary"]
    assert s["total"] == len(items)
    assert s["available"] == sum(i["available"] for i in items)
    assert s["unavailable"] == s["total"] - s["available"]
    assert s["estimated_total_vnd"] == sum(i["subtotal_vnd"] for i in items if i["available"])


def test_given_normalized_name_is_used():
    item = first_item(post_cart([{"name": "Tên bất kỳ", "normalized_name": "ca_chua", "quantity": 2, "unit": "quả"}]))
    assert item["available"] is True


def test_request_id_echo_and_generated():
    assert post_cart([{"name": "Cà chua", "quantity": 1, "unit": "quả"}], request_id="req-001").json()["data"]["request_id"] == "req-001"
    assert post_cart([{"name": "Cà chua", "quantity": 1, "unit": "quả"}]).json()["data"]["request_id"].startswith("req_")


def test_invalid_input_returns_422():
    assert post_cart([{"name": "Cà chua", "quantity": 0, "unit": "quả"}]).status_code == 422
    assert post_cart([]).status_code == 422


def test_notion_page_id_from_n8n():
    body = {"dish": {"id": 1, "name": "x"}, "ingredients": [{"name": "Cà chua", "quantity": 1, "unit": "quả"}]}
    with patch("app.routers.cart.sync_to_n8n", return_value={"notion_page_id": "abc"}):
        r = client.post("/api/v1/cart", json=body)
    assert r.json()["data"]["notion_page_id"] == "abc"