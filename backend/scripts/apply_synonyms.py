import json
from collections import Counter
from datetime import datetime
from pathlib import Path

from app.db.models import Dish
from app.db.session import SessionLocal
from app.services.ingredient_service import display_key

DRY_RUN = False
RULES_PATH = Path("app/data/ingredient_rules.json")

raw = json.loads(Path("llm_output.json").read_text(encoding="utf-8"))
synonyms = raw.get("synonyms", {})
overrides = {display_key(k): v for k, v in raw.get("overrides", {}).items()}

with SessionLocal() as db:
    dishes = db.query(Dish).all()

    if not DRY_RUN:  # backup TRƯỚC khi sửa, mỗi lần một file riêng
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        Path(f"ingredients_backup_{stamp}.json").write_text(
            json.dumps({d.id: d.ingredients for d in dishes}, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    existing = {i["normalized_name"] for d in dishes for i in (d.ingredients or [])}
    shown = {display_key(i["ingredient"]) for d in dishes for i in (d.ingredients or [])}

    problems = []
    for old, new in synonyms.items():
        if old == new:
            problems.append(f"{old} -> chính nó")
        if new not in existing:
            problems.append(f"{old} -> {new}: key chuẩn không có trong DB")
        if new in synonyms:
            problems.append(f"{old} -> {new}: key chuẩn lại bị đổi tiếp ({new} -> {synonyms[new]})")
        if old not in existing:
            print(f"[lưu ý] key {old} không có trong DB (có thể dùng cho món sinh sau)")
    for disp in overrides:
        if disp not in shown:
            print(f"[lưu ý] override '{disp}' không khớp tên hiển thị nào trong DB")
    if problems:
        print("LỖI bảng đồng nghĩa, dừng lại:")
        for p in problems:
            print(" -", p)
        raise SystemExit(1)

    applied = Counter()
    changed = 0
    for d in dishes:
        if not d.ingredients:
            continue
        merged = {}
        for i in d.ingredients:
            old_key = i["normalized_name"]
            new_key = overrides.get(display_key(i["ingredient"])) or synonyms.get(old_key, old_key)
            if new_key != old_key:
                applied[f"{old_key} -> {new_key}"] += 1
            k = (new_key, i["unit"])
            if k in merged:
                merged[k]["quantity"] = round(merged[k]["quantity"] + i["quantity"], 2)
                print(f"   [gộp dòng trùng] {d.name}: {new_key} ({i['unit']})")
            else:
                merged[k] = {**i, "normalized_name": new_key}
        new_list = list(merged.values())
        if new_list != d.ingredients:
            changed += 1
            print(f"[đổi] {d.name}")
            if not DRY_RUN:
                d.ingredients = new_list

    print("\nTên được đổi:")
    for change, n in applied.most_common():
        print(f"  {change}: {n} dòng")
    print(f"\n{changed}/{len(dishes)} món bị ảnh hưởng. DRY_RUN={DRY_RUN}")

    if not DRY_RUN:
        db.commit()
        RULES_PATH.parent.mkdir(parents=True, exist_ok=True)
        RULES_PATH.write_text(
            json.dumps({"synonyms": synonyms, "overrides": overrides}, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        print("Đã ghi DB và", RULES_PATH)