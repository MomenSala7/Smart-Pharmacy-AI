from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from database import Base
import datetime

# 1. جدول المنتجات / الأدوية
class Product(Base):
    __tablename__ = "Product"
    
    id = Column(Integer, primary_key=True, index=True)
    brand_name = Column(String, index=True)
    category = Column(String)
    unit_price = Column(Float)

    # العلاقات
    inventory = relationship("Inventory", back_populates="product", uselist=False)
    shipments = relationship("Shipment", back_populates="product")

# 2. جدول المخزون (اللي فيه تفاصيل الذكاء الاصطناعي)
class Inventory(Base):
    __tablename__ = "Inventory"
    
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("Product.id"))
    stock_level = Column(Integer)
    min_stock = Column(Integer, default=10)
    daily_usage = Column(Float, default=1.0)
    lead_time_days = Column(Integer, default=3)

    product = relationship("Product", back_populates="inventory")

# 3. جدول العملاء
class Customer(Base):
    __tablename__ = "Customer"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    
    shipments = relationship("Shipment", back_populates="customer")

# 4. جدول الشيفتات
class Shift(Base):
    __tablename__ = "Shift"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    
    shipments = relationship("Shipment", back_populates="shift")

# 5. جدول المواسم
class Season(Base):
    __tablename__ = "Season"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    
    shipments = relationship("Shipment", back_populates="season")

# 6. جدول المبيعات / الشحنات
class Shipment(Base):
    __tablename__ = "Shipment"
    
    id = Column(Integer, primary_key=True, index=True)
    date = Column(DateTime, default=datetime.datetime.utcnow)
    boxes_shipped = Column(Integer)
    
    # مفاتيح الربط
    product_id = Column(Integer, ForeignKey("Product.id"))
    customer_id = Column(Integer, ForeignKey("Customer.id"))
    shift_id = Column(Integer, ForeignKey("Shift.id"))
    season_id = Column(Integer, ForeignKey("Season.id"))

    # العلاقات
    product = relationship("Product", back_populates="shipments")
    customer = relationship("Customer", back_populates="shipments")
    shift = relationship("Shift", back_populates="shipments")
    season = relationship("Season", back_populates="shipments")