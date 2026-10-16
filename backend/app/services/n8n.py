import logging

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)


def sync_to_n8n(payload: dict) -> dict | None:
    """Gửi danh sách đã map sang n8n. Lỗi thì trả None, không làm hỏng luồng chính."""
    url = settings.n8n_bhx_webhook_url
    if not url:
        return None
    try:
        r = httpx.post(url, json=payload, timeout=8.0)
        r.raise_for_status()
        data = r.json()
        return data if isinstance(data, dict) else None
    except Exception as e:
        logger.warning("Gọi n8n thất bại: %s", e)
        return None