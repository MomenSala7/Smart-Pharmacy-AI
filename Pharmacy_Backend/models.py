from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from database import Base
import datetime

class Product(Base):
    __tablename__ = "Product"
    
    id = Column(Integer, primary_key=True, index=True)
    brand_name = Column(String, index=True)
    category = Column(String)
    unit_price = Column(Float)

    inventory = relationship("Inventory", back_populates="product", uselist=False)
    shipments = relationship("Shipment", back_populates="product")
    procurement_orders = relationship("ProcurementOrder", back_populates="product") # الربط مع جدول الطلبيات الجديد

class Inventory(Base):
    __tablename__ = "Inventory"
    
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("Product.id"))
    stock_level = Column(Integer)
    min_stock = Column(Integer, default=10)
    daily_usage = Column(Float, default=1.0)
    lead_time_days = Column(Integer, default=3)

    product = relationship("Product", back_populates="inventory")

class Customer(Base):
    __tablename__ = "Customer"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    
    shipments = relationship("Shipment", back_populates="customer")

class Shift(Base):
    __tablename__ = "Shift"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    
    shipments = relationship("Shipment", back_populates="shift")

class Season(Base):
    __tablename__ = "Season"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    
    shipments = relationship("Shipment", back_populates="season")

class Shipment(Base):
    __tablename__ = "Shipment"
    
    id = Column(Integer, primary_key=True, index=True)
    date = Column(DateTime, default=datetime.datetime.utcnow)
    boxes_shipped = Column(Integer)
    
    product_id = Column(Integer, ForeignKey("Product.id"))
    customer_id = Column(Integer, ForeignKey("Customer.id"))
    shift_id = Column(Integer, ForeignKey("Shift.id"))
    season_id = Column(Integer, ForeignKey("Season.id"))

    product = relationship("Product", back_populates="shipments")
    customer = relationship("Customer", back_populates="shipments")
    shift = relationship("Shift", back_populates="shipments")
    season = relationship("Season", back_populates="shipments")

class ProcurementOrder(Base):
    __tablename__ = "ProcurementOrder"
    
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("Product.id"))
    
    suggested_quantity = Column(Integer) 
    requested_quantity = Column(Integer) 
    urgency_tag = Column(String)         
    total_cost = Column(Float)           
    status = Column(String, default="Pending") 
    order_date = Column(DateTime, default=datetime.datetime.utcnow)

    product = relationship("Product", back_populates="procurement_orders")