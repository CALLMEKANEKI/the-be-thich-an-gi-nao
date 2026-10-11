import re
import unicodedata

SYNONYMS: dict[str, str] = {}  


def slugify(text: str) -> str:
    text = text.strip().lower().replace("đ", "d")  
    text = unicodedata.normalize("NFD", text)
    text = "".join(c for c in text if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]+", "_", text).strip("_")