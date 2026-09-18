import os
from pathlib import Path
from dotenv import load_dotenv

_ENV_PATH = Path(__file__).resolve().parent.parent.parent / ".env"
load_dotenv(_ENV_PATH)

class Setting():
    database_url: str=os.getenv("DATABASE_URL")
    gemini_api_key: str=os.getenv("GEMINI_API_KEY")
    n8n_bhx_webhook_url: str=os.getenv("N8N_BHX_WEBHOOK_URL")
    weather_api_key: str=os.getenv("WEATHER_API_KEY")
    map_api_key: str=os.getenv("MAP_API_KEY")
        
settings = Setting()