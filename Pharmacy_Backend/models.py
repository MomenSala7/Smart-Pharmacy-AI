from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from database import Base
import datetime

class Medication(Base):
    __tablename__ = "medications"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    category = Column(String)
    current_stock = Column(Integer, default=0)
    price = Column(Float)
    
    # الرفوف الجديدة اللي الموديل محتاجها:
    min_stock = Column(Integer, default=10) 
    daily_usage = Column(Float, default=1.0)
    lead_time_days = Column(Integer, default=3)

class Sale(Base):
    __tablename__ = "sales"

    id = Column(Integer, primary_key=True, index=True)
    medication_id = Column(Integer, ForeignKey("medications.id"))
    quantity_sold = Column(Integer)
    sale_date = Column(DateTime, default=datetime.datetime.utcnow)