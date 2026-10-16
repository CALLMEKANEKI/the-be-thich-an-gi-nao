import csv
from collections import Counter

PATH = "data/sku_catalog.csv"
rows = list(csv.DictReader(open(PATH, encoding="utf-8-sig")))

blank, no_product, errors, warnings = [], [], [], []


def to_number(value):
    try:
        return float(value)
    except ValueError:
        return None


def ranges(nums):
    out, start, prev = [], None, None
    for n in nums:
        if start is None:
            start = prev = n
        elif n == prev + 1:
            prev = n
        else:
            out.append((start, prev))
            start = prev = n
    if start is not None:
        out.append((start, prev))
    return ", ".join(str(a) if a == b else f"{a}-{b}" for a, b in out)


for line_no, r in enumerate(rows, start=2):
    where = f"dòng {line_no} ({r['normalized_name']}, {r['unit']})"
    fields = [r["product_name"], r["search_keyword"], r["pack_size"], r["price_vnd"]]

    if not any(f.strip() for f in fields):
        blank.append(line_no)
        continue
    if r["product_name"].strip() == "KHONG_CO":
        no_product.append(where)
        continue

    for col in ("product_name", "search_keyword"):
        if not r[col].strip():
            errors.append(f"{where}: thiếu {col}")
    for col in ("pack_size", "price_vnd"):
        num = to_number(r[col])
        if num is None or num <= 0:
            errors.append(f"{where}: {col} phải là số > 0 (đang là {r[col]!r})")
        elif col == "price_vnd" and num < 1000:
            warnings.append(f"{where}: price_vnd = {r[col]}, có thể gõ nhầm kiểu '45.000' (phải là 45000)")

for label, values in (
    ("sku", [r["sku"] for r in rows]),
    ("(normalized_name, unit)", [(r["normalized_name"], r["unit"]) for r in rows]),
):
    dup = [v for v, n in Counter(values).items() if n > 1]
    if dup:
        errors.append(f"{label} trùng: {dup}")

print(f"{len(rows)} dòng")
print(f"- Chưa điền gì: {len(blank)} dòng" + (f" (dòng {ranges(blank)})" if blank else ""))
print(f"- KHONG_CO (cần quyết định): {len(no_product)} dòng")
print(f"- Lỗi định dạng: {len(errors)}")
print(f"- Cảnh báo: {len(warnings)}")
for title, items in (("KHONG_CO", no_product), ("LỖI", errors), ("CẢNH BÁO", warnings)):
    if items:
        print(f"\n{title}:")
        for item in items:
            print(" -", item)