from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List

import pandas as pd
import numpy as np
import datetime
import joblib

import models
from database import engine, SessionLocal


models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Pharmacy Shortage Prediction System 🚀")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

try:
    ml_model = joblib.load('shortage_model.joblib')
    print("✅ AI Model (Prophet) loaded successfully!")
except Exception as e:
    print(f"❌ Error loading AI model: {e}")
    ml_model = None

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class MedicationCreate(BaseModel):
    name: str
    category: str
    current_stock: int
    price: float
    min_stock: int
    daily_usage: float
    lead_time_days: int

class SellMedication(BaseModel):
    quantity: int

class OrderItem(BaseModel):
    product_id: int
    requested_quantity: int
    total_cost: float
    urgency_tag: str

class OrderConfirmRequest(BaseModel):
    items: List[OrderItem]



@app.get("/")
def read_root():
    """مسار اختبار السيرفر"""
    return {"message": "Advanced Pharmacy AI is Ready! "}

@app.post("/add_medication/")
def add_medication(med: MedicationCreate, db: Session = Depends(get_db)):
    """إضافة دواء جديد لقاعدة البيانات (موزع على جدولين)"""
    
    new_product = models.Product(
        brand_name=med.name, 
        category=med.category,
        unit_price=med.price
    )
    db.add(new_product)
    db.commit()
    db.refresh(new_product) 

    new_inventory = models.Inventory(
        product_id=new_product.id,
        stock_level=med.current_stock,
        min_stock=med.min_stock,
        daily_usage=med.daily_usage,
        lead_time_days=med.lead_time_days
    )
    db.add(new_inventory)
    db.commit()

    return {"message": "✅ تم إضافة الدواء والمخزون بنجاح!", "product_id": new_product.id}

@app.get("/medications/")
def get_all_medications(db: Session = Depends(get_db)):
    """سحب كل الأدوية عشان نعرضها في شاشة فلاتر (الداشبورد)"""
    
    results = db.query(models.Product, models.Inventory).join(models.Inventory).all()
    
    medications = []
    for product, inventory in results:
        medications.append({
            "id": product.id,
            "name": product.brand_name, 
            "category": product.category,
            "price": product.unit_price,
            "current_stock": inventory.stock_level,
            "min_stock": inventory.min_stock,
            "daily_usage": inventory.daily_usage,
            "lead_time_days": inventory.lead_time_days
        })
    return medications

@app.delete("/delete_medication/{med_id}")
def delete_medication(med_id: int, db: Session = Depends(get_db)):
    """حذف دواء من قاعدة البيانات باستخدام الـ ID بتاعه"""
    
    inventory = db.query(models.Inventory).filter(models.Inventory.product_id == med_id).first()
    product = db.query(models.Product).filter(models.Product.id == med_id).first()
    
    if not product:
        raise HTTPException(status_code=404, detail="❌ الدواء غير موجود")
        
    if inventory:
        db.delete(inventory)
        
    db.delete(product)
    db.commit()
    return {"message": "🗑️ تم حذف الدواء والمخزون بنجاح"}

@app.put("/sell_medication/{med_id}")
def sell_medication(med_id: int, sale: SellMedication, db: Session = Depends(get_db)):
    """عملية الكاشير: بيع دواء وخصم الكمية من المخزن وتسجيل الشحنة"""
    
    
    inventory = db.query(models.Inventory).filter(models.Inventory.product_id == med_id).first()
    
    if not inventory:
        raise HTTPException(status_code=404, detail="عذراً، مخزون هذا الدواء غير مسجل!")
    
    
    if inventory.stock_level < sale.quantity:
        raise HTTPException(
            status_code=400, 
            detail=f"الكمية لا تكفي! المتاح فقط {inventory.stock_level} علبة."
        )
        
    inventory.stock_level -= sale.quantity
    
    new_shipment = models.Shipment(
        product_id=med_id,
        boxes_shipped=sale.quantity,
        customer_id=1, 
        shift_id=1,
        season_id=1
    )
    db.add(new_shipment)
    
    db.commit()
    
    return {"message": "✅ تمت عملية البيع وتسجيل الشحنة بنجاح", "remaining_stock": inventory.stock_level}

@app.get("/predict/{med_id}")
def predict_shortage(med_id: int, db: Session = Depends(get_db)):
    """تحليل الذكاء الاصطناعي: دمج تريند السوق العام مع أرقام الدواء الفعلي"""
    
    product = db.query(models.Product).filter(models.Product.id == med_id).first()
    inventory = db.query(models.Inventory).filter(models.Inventory.product_id == med_id).first()
    
    if not product or not inventory:
        raise HTTPException(status_code=404, detail="❌ الدواء أو مخزونه مش موجود!")

    if ml_model is None:
        raise HTTPException(status_code=500, detail="❌ الموديل غير متاح حالياً")

    try:
        current_date = datetime.datetime.now()
        future_dates = pd.DataFrame({
            'ds': pd.date_range(start=current_date, periods=7)
        })

        forecast = ml_model.predict(future_dates)
        predicted_trend = forecast['yhat'].values
        
        start_stock = predicted_trend[0]
        end_stock = predicted_trend[-1]
        
        trend_drop_percentage = 0
        if start_stock > 0 and end_stock < start_stock:
            trend_drop_percentage = (start_stock - end_stock) / start_stock

        if inventory.stock_level > 0:
            drug_pressure = (inventory.daily_usage * 7) / inventory.stock_level
        else:
            drug_pressure = 1.0 

        if inventory.stock_level <= inventory.min_stock:
            
            probability = 0.85 + trend_drop_percentage 
        else:
            
            probability = drug_pressure + (trend_drop_percentage * 0.5)

        
        probability = min(0.99, max(0.01, probability))

        
        is_shortage = bool(probability > 0.4)
        status = "Critical Warning" if is_shortage else "Safe"

        return {
            "medication_id": product.id,
            "medication_name": product.brand_name,
            "current_stock": inventory.stock_level,
            "shortage_probability": f"{probability:.1%}",
            "status": status,
            "message": "⚠️ الذكاء الاصطناعي يتوقع نقص الدواء قريباً!" if is_shortage else "✅ المخزون والمؤشرات المستقبلية آمنة."
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI Prediction Error: {str(e)}")


@app.get("/api/procurement/suggestions")
def get_procurement_suggestions(db: Session = Depends(get_db)):
    
    low_stock_items = db.query(models.Product).join(models.Inventory).filter(
        models.Inventory.stock_level <= models.Inventory.min_stock
    ).all()

    suggestions = []
    for product in low_stock_items:
        inv = product.inventory
        
        
        suggested_qty = (inv.min_stock - inv.stock_level) + int(inv.daily_usage * 30)
        if suggested_qty <= 0:
            suggested_qty = 10 

        
        if inv.stock_level == 0:
            urgency = "Critical"
        elif inv.stock_level <= (inv.min_stock / 2):
            urgency = "High"
        else:
            urgency = "Moderate"

        est_cost = suggested_qty * product.unit_price

        suggestions.append({
            "product_id": product.id,
            "brand_name": product.brand_name,
            "current_stock": inv.stock_level,
            "suggested_quantity": suggested_qty,
            "unit_price": product.unit_price,
            "estimated_total_cost": round(est_cost, 2),
            "urgency_tag": urgency
        })
    return suggestions

@app.post("/api/procurement/confirm")
def confirm_procurement_order(order_req: OrderConfirmRequest, db: Session = Depends(get_db)):
    try:
        for item in order_req.items:
            new_order = models.ProcurementOrder(
                product_id=item.product_id,
                suggested_quantity=item.requested_quantity,
                requested_quantity=item.requested_quantity,
                urgency_tag=item.urgency_tag,
                total_cost=item.total_cost,
                status="Pending"
            )
            db.add(new_order)
        db.commit()
        return {"message": "Order confirmed successfully", "status": "success"}
    except Exception as e:
        db.rollback()
        return {"error": str(e)}