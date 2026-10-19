import csv
import re
import sys
from collections import Counter
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND_DIR))

errors = []
warnings = []


def to_number(value):
    if value is None:
        return None

    text = str(value).strip()
    if not text or text.lower() in {"nan", "none", "null"}:
        return None

    text = text.replace(" ", "").replace("₫", "").replace("VND", "")
    match = re.search(r"[-+]?\d[\d,\.]*", text)
    if not match:
        return None

    number = match.group(0)

    if "," in number and "." in number:
        if number.rfind(",") > number.rfind("."):
            number = number.replace(".", "").replace(",", ".")
        else:
            number = number.replace(",", "")
    elif "," in number:
        parts = number.split(",")
        if len(parts) > 1 and len(parts[-1]) == 3 and all(part.isdigit() for part in parts):
            number = "".join(parts)
        else:
            number = number.replace(",", ".")
    elif "." in number:
        parts = number.split(".")
        if len(parts) > 1 and len(parts[-1]) == 3 and all(part.isdigit() for part in parts):
            number = "".join(parts)

    try:
        return float(number)
    except ValueError:
        return None


with open(BACKEND_DIR / "data" / "sku_catalog.csv", encoding="utf-8-sig", newline="") as f:
    rows = list(csv.DictReader(f))

for line_no, r in enumerate(rows, start=2):
    normalized = (r.get("normalized_name") or "").strip()
    product_name = (r.get("product_name") or "").strip()
    search_keyword = (r.get("search_keyword") or "").strip()
    where = f"dòng {line_no} ({normalized})"

    if not product_name:
        errors.append(f"{where}: thiếu product_name")
    elif product_name == "KHONG_CO":
        errors.append(f"{where}: không có sản phẩm, cần quyết định")

    if not search_keyword:
        errors.append(f"{where}: thiếu search_keyword")

    for col in ("pack_size", "price_vnd"):
        try:
            value = float(to_number(r.get(col, "")) or 0)
            if value <= 0:
                errors.append(f"{where}: {col} phải > 0")
        except (TypeError, ValueError):
            errors.append(f"{where}: {col} không phải số ({r.get(col)!r})")


dup = [sku for sku, count in Counter(r.get("sku") for r in rows).items() if count > 1]
if dup:
    errors.append(f"sku trùng: {dup}")

COUNT_UNITS = {"quả", "củ", "tép", "con", "miếng", "bó"}
by_product = {}
for line_no, r in enumerate(rows, start=2):
    product_name = (r.get("product_name") or "").strip()
    if product_name in ("", "KHONG_CO"):
        continue

    pack = to_number(r.get("pack_size"))
    price = to_number(r.get("price_vnd"))
    if pack is None or price is None:
        continue

    where = f"dòng {line_no} ({r.get('normalized_name', '')}, {r.get('unit', '')})"
    if r.get("unit", "") in COUNT_UNITS and pack > 100:
        warnings.append(f"{where}: pack_size = {pack:g} {r.get('unit', '')}, nghi ghi nhầm gram")
    by_product.setdefault(product_name, set()).add(price)

for name, prices in by_product.items():
    if len(prices) > 1:
        warnings.append(f"cùng sản phẩm '{name[:40]}' nhưng giá khác nhau: {sorted(prices)}")

print(f"{len(rows)} dòng, {len(errors)} lỗi, {len(warnings)} cảnh báo")
for e in errors:
    print(" -", e)
for w in warnings:
    print(" !", w)