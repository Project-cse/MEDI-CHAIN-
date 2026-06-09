import os
from dotenv import load_dotenv
from pathlib import Path

# Load .env from the current backend directory (fastapi_back)
env_path = Path(__file__).resolve().parent.parent.parent / '.env'
load_dotenv(dotenv_path=env_path)

class Config:
    JWT_SECRET = os.getenv("JWT_SECRET", "greatstack")
    ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "15"))
    REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "30"))
    CURRENCY = os.getenv("CURRENCY", "INR").replace('"', '').replace("'", "").strip()
    PORT = int(os.getenv("PORT", 5000))
    DEBUG = os.getenv("DEBUG", "true").lower() == "true"
    
    # Admin Credentials
    ADMIN_EMAIL = os.getenv("ADMIN_EMAIL")
    ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD")
    
    # PostgreSQL
    DATABASE_URL = os.getenv("DATABASE_URL")
    PG_USER = os.getenv("PG_USER", "postgres")
    PG_HOST = os.getenv("PG_HOST", "localhost")
    PG_DATABASE = os.getenv("PG_DATABASE", "healthsystem_pg")
    PG_PASSWORD = os.getenv("PG_PASSWORD", "Javali786")
    PG_PORT = int(os.getenv("PG_PORT", 5432))
    PG_SSL = os.getenv("PG_SSL", "false").lower() == "true"
    
    # MongoDB
    MONGODB_URI = os.getenv("MONGODB_URI")
    
    # Cloudinary
    CLOUDINARY_NAME = os.getenv("CLOUDINARY_NAME")
    CLOUDINARY_API_KEY = os.getenv("CLOUDINARY_API_KEY")
    CLOUDINARY_API_SECRET = os.getenv("CLOUDINARY_API_SECRET") or os.getenv("CLOUDINARY_SECRET_KEY")
    
    # Payments
    RAZORPAY_KEY_ID = os.getenv("RAZORPAY_KEY_ID")
    RAZORPAY_KEY_SECRET = os.getenv("RAZORPAY_KEY_SECRET")
    STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY")
    PAYU_MERCHANT_KEY = os.getenv("PAYU_MERCHANT_KEY")
    PAYU_MERCHANT_SALT = os.getenv("PAYU_MERCHANT_SALT")
    PAYU_BASE_URL = os.getenv("PAYU_BASE_URL")
    
    # AI
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    MISTRAL_API_KEY = os.getenv("MISTRAL_API_KEY")
    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
    
    # MediChain Bot Integration
    MEDICHAIN_BOT_BASE_URL = os.getenv("MEDICHAIN_BOT_BASE_URL", "http://3.7.203.166")
    MEDICHAIN_BOT_API_KEY = os.getenv("MEDICHAIN_BOT_API_KEY", "sk_XYrHA9HSP9VVSoTQJNCR6Dt2tqFYXkSu")
    MEDICHAIN_BOT_PASSWORD = os.getenv("MEDICHAIN_BOT_PASSWORD", "Javali786")
    TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
    # Set false if another process (e.g. external server) already polls this token
    TELEGRAM_BOT_ENABLED = os.getenv("TELEGRAM_BOT_ENABLED", "true").lower() == "true"

    # Agora
    AGORA_APP_ID = os.getenv("AGORA_APP_ID")
    AGORA_APP_CERTIFICATE = os.getenv("AGORA_APP_CERTIFICATE")

    
    # Email (Brevo/SMTP)
    BREVO_API_KEY = os.getenv("BREVO_API_KEY") or os.getenv("BERVO_API_KEY")
    BREVO_SENDER_EMAIL = os.getenv("BREVO_SENDER_EMAIL") or os.getenv("BERVO_SENDER_EMAIL")
    BREVO_APP_NAME = os.getenv("BREVO_APP_NAME") or os.getenv("BERVO_APP_NAME")
    
    EMAIL_USER = os.getenv("EMAIL_USER")
    EMAIL_APP_PASSWORD = os.getenv("EMAIL_APP_PASSWORD")
    
    # URLs
    FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:5173")
    BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:5000")
    
    # Fees
    PLATFORM_FEE_PERCENTAGE = float(os.getenv("PLATFORM_FEE_PERCENTAGE", 5))
    GST_PERCENTAGE = float(os.getenv("GST_PERCENTAGE", 18))

settings = Config()
