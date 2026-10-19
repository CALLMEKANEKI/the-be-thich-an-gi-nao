import unicodedata
from unittest.mock import patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.routers import dishes
from app.services import dish_service as ds


def dish(i, name, category="món nước"):
    return {"id": i, "name": name, "description": f"Mô tả {name}", "image_url": "", "category": category}


DISHES = [
    dish(1, "Phở bò"),
    dish(2, "Bún chả"),
    dish(3, "Bánh xèo", "món chiên"),
    dish(4, "Cơm tấm", "Món mặn"),
    dish(5, "Chè đậu xanh", "đồ ngọt"),
]


def names(items):
    return [d["name"] for d in items]


# ---------------- logic thuần ----------------
def test_sort_ignores_diacritics():
    assert names(ds.filter_and_sort(DISHES)) == ["Bánh xèo", "Bún chả", "Chè đậu xanh", "Cơm tấm", "Phở bò"]


@pytest.mark.parametrize("q, expected", [
    ("pho", ["Phở bò"]),
    ("PHỞ BÒ", ["Phở bò"]),
    ("bun", ["Bún chả"]),
    ("xanh", ["Chè đậu xanh"]),
    ("zzz", []),
])
def test_search_ignores_accents_and_case(q, expected):
    assert names(ds.filter_and_sort(DISHES, q=q)) == expected


def test_punctuation_only_query_is_ignored():
    assert len(ds.filter_and_sort(DISHES, q="  !!  ")) == len(DISHES)


def test_category_filter_normalizes_case_and_unicode_form():
    nfd = unicodedata.normalize("NFD", "MÓN MẶN")
    assert names(ds.filter_and_sort(DISHES, category=nfd)) == ["Cơm tấm"]
    assert names(ds.filter_and_sort(DISHES, category="món nước")) == ["Bún chả", "Phở bò"]


def test_search_and_category_combine():
    assert names(ds.filter_and_sort(DISHES, q="bun", category="món nước")) == ["Bún chả"]
    assert ds.filter_and_sort(DISHES, q="bun", category="món chiên") == []


def test_build_categories_groups_variants_and_counts():
    extra = [dish(6, "Lẩu", "  món   NƯỚC "), dish(7, "Khác", "")]
    cats = ds.build_categories(DISHES + extra)
    assert cats[0] == {"name": "món nước", "count": 3}
    assert {c["name"] for c in cats} == {"món nước", "món chiên", "Món mặn", "đồ ngọt"}  # bỏ nhóm rỗng


def test_search_dishes_total_and_page(monkeypatch):
    monkeypatch.setattr(ds, "load_all_dishes", lambda: DISHES)
    total, page = ds.search_dishes(None, None, limit=2, offset=2)
    assert total == 5
    assert names(page) == ["Chè đậu xanh", "Cơm tấm"]
    assert ds.search_dishes(None, None, limit=2, offset=10) == (5, [])


# ---------------- router ----------------
app = FastAPI()
app.include_router(dishes.router)
client = TestClient(app)


def test_list_contract_and_defaults():
    with patch.object(dishes.dish_service, "search_dishes", return_value=(5, DISHES[:2])) as search:
        r = client.get("/api/v1/dishes")
    assert r.status_code == 200
    assert r.json() == {"success": True, "data": {"total": 5, "limit": 20, "offset": 0, "items": DISHES[:2]}}
    search.assert_called_once_with(None, None, 20, 0)


def test_list_forwards_query_params():
    with patch.object(dishes.dish_service, "search_dishes", return_value=(0, [])) as search:
        client.get("/api/v1/dishes", params={"q": "phở", "category": "món nước", "limit": 5, "offset": 10})
    search.assert_called_once_with("phở", "món nước", 5, 10)


@pytest.mark.parametrize("params", [{"limit": 0}, {"limit": 101}, {"offset": -1}])
def test_list_rejects_bad_paging(params):
    assert client.get("/api/v1/dishes", params=params).status_code == 422


def test_categories_route_is_not_captured_by_dish_id():
    cats = [{"name": "món nước", "count": 2}]
    with patch.object(dishes.dish_service, "list_categories", return_value=cats):
        r = client.get("/api/v1/dishes/categories")
    assert r.status_code == 200
    assert r.json() == {"success": True, "data": cats}


def test_detail_ok_404_422_503():
    with patch.object(dishes.dish_service, "get_dish", return_value=DISHES[0]):
        r = client.get("/api/v1/dishes/1")
    assert r.status_code == 200 and r.json() == {"success": True, "data": DISHES[0]}

    with patch.object(dishes.dish_service, "get_dish", return_value=None):
        assert client.get("/api/v1/dishes/999").status_code == 404

    assert client.get("/api/v1/dishes/abc").status_code == 422

    with patch.object(dishes.dish_service, "get_dish", side_effect=RuntimeError("DB lỗi")):
        assert client.get("/api/v1/dishes/1").status_code == 503


def test_list_db_failure_returns_503():
    with patch.object(dishes.dish_service, "search_dishes", side_effect=RuntimeError("DB lỗi")):
        assert client.get("/api/v1/dishes").status_code == 503