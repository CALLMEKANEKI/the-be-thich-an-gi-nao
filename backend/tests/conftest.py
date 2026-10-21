import os
import sys
from types import ModuleType
from unittest.mock import MagicMock

# Đặt TRƯỚC khi import app, để test không bao giờ chạm DB hay n8n thật.
# (load_dotenv không ghi đè biến môi trường đã có, nên file .env thật bị bỏ qua.)
os.environ["DATABASE_URL"] = "postgresql+psycopg://test:test@localhost:5432/test"
os.environ["N8N_BHX_WEBHOOK_URL"] = ""


def _stub(name, **attrs):
    module = ModuleType(name)
    for key, value in attrs.items():
        setattr(module, key, value)
    sys.modules[name] = module


# Hai module này nạp model PhoBERT / tạo client Gemini ngay lúc import nên phải thay bằng bản giả.
_stub("app.services.emotion_model", emotion_service=MagicMock())
_stub(
    "app.services.ai_agent",
    client=MagicMock(),
    MODELS_TO_TRY=["test-model"],
    recommend_dish=MagicMock(),
)