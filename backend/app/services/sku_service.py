import csv
import logging
import math
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from urllib.parse import quote

from app.schemas.cart import CartIngredient, CartItem, CartSummary
from app.services.ingredient_service import normalize_key

logger = logging.getLogger(__name__)

CATALOG_PATH = Path(__file__).resolve().parent.parent.parent / "data" / "sku_catalog.csv"
# TODO: mở bachhoaxanh.com, tìm thử một sản phẩm và xác nhận tên tham số tìm kiếm thật trong URL
BHX_SEARCH_URL = "https://www.bachhoaxanh.com/tim-kiem?q={q}"
NOT_FOUND_NOTE = "Chưa tìm thấy trên Bách Hoá Xanh"
NO_PRODUCT_MARK = "KHONG_CO"
MIN_PRICE_VND = 1000  # giá thấp hơn thường là gõ nhầm (vd "45.000" thành 45)


@dataclass(frozen=True)
class Product:
    sku: str
    product_name: str
    pack_size: float
    price_vnd: int
    search_keyword: str


@lru_cache(maxsize=1)
def get_catalog() -> dict[tuple[str, str], Product]:
    """Nạp catalog một lần. Key = (normalized_name, unit)."""
    catalog: dict[tuple[str, str], Product] = {}
    if not CATALOG_PATH.exists():
        logger.error("Không tìm thấy catalog %s: mọi nguyên liệu sẽ trả available=false", CATALOG_PATH)
        return catalog

    with CATALOG_PATH.open(encoding="utf-8-sig", newline="") as f:
        for line_no, row in enumerate(csv.DictReader(f), start=2):
            product_name = (row.get("product_name") or "").strip()
            if not product_name or product_name == NO_PRODUCT_MARK:
                continue  # chưa có sản phẩm -> coi như không có trong catalog

            key = ((row.get("normalized_name") or "").strip(), (row.get("unit") or "").strip().lower())
            sku = (row.get("sku") or "").strip()
            try:
                pack_size = float(row.get("pack_size") or "")
                price = float(row.get("price_vnd") or "")
            except ValueError:
                logger.warning("Catalog dòng %d %s: pack_size/price_vnd không phải số, bỏ qua", line_no, key)
                continue

            if not sku or pack_size <= 0 or price < MIN_PRICE_VND:
                logger.warning("Catalog dòng %d %s: sku/pack_size/giá không hợp lệ (giá=%s), bỏ qua", line_no, key, price)
                continue
            if key in catalog:
                logger.warning("Catalog dòng %d: trùng %s, giữ dòng đầu tiên", line_no, key)
                continue

            catalog[key] = Product(
                sku=sku,
                product_name=product_name,
                pack_size=pack_size,
                price_vnd=int(round(price)),
                search_keyword=(row.get("search_keyword") or "").strip() or product_name,
            )
    return catalog


def _search_url(keyword: str) -> str:
    return BHX_SEARCH_URL.format(q=quote(keyword))


def map_ingredient(item: CartIngredient) -> CartItem:
    normalized = item.normalized_name or normalize_key(item.name)
    unit = item.unit.strip().lower()
    base = {
        "ingredient": " ".join(item.name.split()),
        "normalized_name": normalized,
        "quantity": item.quantity,
        "unit": unit,
    }

    product = get_catalog().get((normalized, unit))
    if product is None:
        return CartItem(**base, available=False, note=NOT_FOUND_NOTE)

    # round(..., 6) tránh lỗi số thực kiểu 2.0000000000000004 làm ceil nhảy lên 3
    packs = max(1, math.ceil(round(item.quantity / product.pack_size, 6)))
    return CartItem(
        **base,
        available=True,
        sku=product.sku,
        product_name=product.product_name,
        pack_size=product.pack_size,
        packs_needed=packs,
        price_vnd=product.price_vnd,
        subtotal_vnd=packs * product.price_vnd,
        search_url=_search_url(product.search_keyword),
    )


def build_cart(ingredients: list[CartIngredient]) -> tuple[list[CartItem], CartSummary]:
    items = [map_ingredient(i) for i in ingredients]
    available = [i for i in items if i.available]
    summary = CartSummary(
        total=len(items),
        available=len(available),
        unavailable=len(items) - len(available),
        estimated_total_vnd=sum(i.subtotal_vnd for i in available),
    )
    return items, summary