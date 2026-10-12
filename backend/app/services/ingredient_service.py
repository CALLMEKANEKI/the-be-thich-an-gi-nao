import json
import re
import unicodedata
from pathlib import Path

_RULES_PATH = Path(__file__).resolve().parent.parent / "data" / "ingredient_rules.json"


def _load_rules() -> tuple[dict[str, str], dict[str, str]]:
    if _RULES_PATH.exists():
        data = json.loads(_RULES_PATH.read_text(encoding="utf-8"))
        return data.get("synonyms", {}), data.get("overrides", {})
    return {}, {}


SYNONYMS, OVERRIDES = _load_rules()


def slugify(text: str) -> str:
    text = text.strip().lower().replace("đ", "d")
    text = unicodedata.normalize("NFD", text)
    text = "".join(c for c in text if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]+", "_", text).strip("_")


def display_key(name: str) -> str:
    return " ".join(unicodedata.normalize("NFC", name).lower().split())


def normalize_key(name: str) -> str:
    """Tên hiển thị -> normalized_name. Override theo tên gốc trước, rồi tới synonyms."""
    override = OVERRIDES.get(display_key(name))
    if override:
        return override
    slug = slugify(name)
    return SYNONYMS.get(slug, slug)