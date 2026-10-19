from types import SimpleNamespace as NS

import httpx
import pytest

from app.core.config import settings
from app.services import ingredient_agent as agent
from app.services import ingredient_service as svc
from app.services import n8n, sku_service
from tests.helpers import FakeResponse


# ---------------- ingredient_service ----------------
@pytest.fixture(autouse=True)
def no_rules(monkeypatch):
    """Không phụ thuộc file ingredient_rules.json thật."""
    monkeypatch.setattr(svc, "SYNONYMS", {})
    monkeypatch.setattr(svc, "OVERRIDES", {})


@pytest.mark.parametrize("text, expected", [
    ("Thịt bò", "thit_bo"),
    ("  Đậu   phộng ", "dau_phong"),
    ("Hành lá (tươi)", "hanh_la_tuoi"),
    ("ĐƯỜNG PHÈN", "duong_phen"),
    ("", ""),
])
def test_slugify(text, expected):
    assert svc.slugify(text) == expected
    assert svc.slugify(expected) == expected   # chạy lại nhiều lần vẫn ra cùng kết quả


def test_normalize_key_applies_overrides_then_synonyms(monkeypatch):
    monkeypatch.setattr(svc, "OVERRIDES", {"bơ": "qua_bo", "dứa": "thom"})
    monkeypatch.setattr(svc, "SYNONYMS", {"lac": "dau_phong"})
    assert svc.normalize_key("Bơ") == "qua_bo"
    assert svc.normalize_key("  DỨA ") == "thom"
    assert svc.normalize_key("Lạc") == "dau_phong"
    assert svc.normalize_key("Thịt bò") == "thit_bo"
    assert svc.normalize_key("Bò") == "bo"      # không có override thì ra slug thường


# ---------------- ingredient_agent._clean ----------------
def raw(name, quantity, unit="g"):
    return NS(name=name, quantity=quantity, unit=NS(value=unit))   # unit là Enum nên có .value


def test_clean_drops_invalid_rows_and_normalizes():
    out = agent._clean([raw("Thịt bò", 200), raw("Hành", 0), raw("", 5), raw("  Bánh   phở ", 300.456)])
    assert [i["normalized_name"] for i in out] == ["thit_bo", "banh_pho"]
    assert out[1]["ingredient"] == "Bánh phở"
    assert out[1]["quantity"] == 300.46


def test_clean_accepts_plain_string_unit():
    out = agent._clean([NS(name="Nước mắm", quantity=30, unit="ml")])
    assert out[0]["unit"] == "ml"


def test_clean_raises_when_nothing_is_valid():
    with pytest.raises(ValueError):
        agent._clean([raw("Hành", 0), raw("", 5)])


# ---------------- sku_service: loader chịu được dữ liệu xấu ----------------
@pytest.fixture
def fresh_catalog():
    sku_service.get_catalog.cache_clear()
    yield
    sku_service.get_catalog.cache_clear()   # trả lại catalog thật cho các test khác


def test_catalog_loader_skips_bad_rows(tmp_path, monkeypatch, fresh_catalog):
    csv_path = tmp_path / "catalog.csv"
    csv_path.write_text(
        "sku,normalized_name,ingredient,unit,so_mon_dung,luong_thuong_dung,product_name,pack_size,price_vnd,search_keyword\n"
        "SKU001,ca_chua,Cà chua,g,1,100,Cà chua,300,9240,cà chua\n"
        "SKU002,dau_phu,Đậu phụ,miếng,1,1,Đậu hũ,280,1,đậu phụ\n"          # giá quá thấp, nghi gõ nhầm
        "SKU003,la_gai,Lá gai,g,1,50,KHONG_CO,,,lá gai\n"                    # chưa có sản phẩm
        "SKU004,ca_chua,Cà chua,g,1,100,Cà chua khác,100,5000,cà chua\n"     # trùng khoá, giữ dòng đầu
        ",hanh,Hành,g,1,10,Hành,100,3000,hành\n"                             # thiếu sku
        "SKU006,thom,Dứa,g,1,100,Dứa,500,abc,dứa\n"                         # giá không phải số
        "SKU007,gung,Gừng,g,1,10,Gừng củ,100,4640,gừng\n",
        encoding="utf-8",
    )
    monkeypatch.setattr(sku_service, "CATALOG_PATH", csv_path)

    catalog = sku_service.get_catalog()

    assert set(catalog) == {("ca_chua", "g"), ("gung", "g")}
    assert catalog[("ca_chua", "g")].sku == "SKU001"


# ---------------- n8n: lỗi n8n không được làm hỏng luồng chính ----------------
URL = "http://n8n.test/webhook/bhx-cart"


def fake_post_returning(response):
    def fake_post(url, json=None, timeout=None, **kwargs):
        return response
    return fake_post


def test_n8n_skipped_when_url_empty(monkeypatch):
    monkeypatch.setattr(settings, "n8n_bhx_webhook_url", "")
    monkeypatch.setattr(n8n.httpx, "post", lambda *a, **k: pytest.fail("không được gọi n8n khi URL trống"))
    assert n8n.sync_to_n8n({"x": 1}) is None


def test_n8n_success_returns_response(monkeypatch):
    monkeypatch.setattr(settings, "n8n_bhx_webhook_url", URL)
    monkeypatch.setattr(n8n.httpx, "post",
                        fake_post_returning(FakeResponse({"success": True, "notion_page_id": "abc"})))
    assert n8n.sync_to_n8n({"x": 1})["notion_page_id"] == "abc"


@pytest.mark.parametrize("response", [
    FakeResponse({"success": True}),                   # n8n trả nhưng thiếu notion_page_id
    FakeResponse([{"body": {}}]),                      # không phải dict
    FakeResponse({"error": "x"}, status_code=500),     # n8n báo lỗi
])
def test_n8n_bad_responses_return_none(monkeypatch, response):
    monkeypatch.setattr(settings, "n8n_bhx_webhook_url", URL)
    monkeypatch.setattr(n8n.httpx, "post", fake_post_returning(response))
    assert n8n.sync_to_n8n({"x": 1}) is None


def test_n8n_network_error_returns_none(monkeypatch):
    def boom(*args, **kwargs):
        raise httpx.ConnectError("n8n đang tắt")

    monkeypatch.setattr(settings, "n8n_bhx_webhook_url", URL)
    monkeypatch.setattr(n8n.httpx, "post", boom)
    assert n8n.sync_to_n8n({"x": 1}) is None