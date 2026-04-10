from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# ده السطر اللي بيعمل قاعدة البيانات (SQLite) جوه فولدر المشروع
SQLALCHEMY_DATABASE_URL = "sqlite:///./pharmacy.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()