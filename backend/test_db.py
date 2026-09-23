from sqlalchemy import create_engine
from app.core.config import settings

engine = create_engine(settings.database_url)
with engine.connect() as conn:
    print("Kết nối thành công!")