from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware # السطر ده ضفناه
from sqlalchemy.orm import Session

from pydantic import BaseModel
class SellMedication(BaseModel):
    quantity: int

import models
from database import engine, SessionLocal
import joblib
import pandas as pd
import datetime
import numpy as np

# إنشاء الجداول
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Pharmacy Shortage Prediction System")

# ==========================================
# إضافة إعدادات الـ CORS عشان الفرونت إند (فلاتر) يعرف يكلم السيرفر
# ==========================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# ==========================================

# تحميل الموديل الجديد بتاع زميلك
ml_model = joblib.load('drug_shortage_model.pkl')

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# شكل بيانات الإضافة الجديد
class MedicationCreate(BaseModel):
    name: str
    category: str
    current_stock: int
    price: float
    min_stock: int
    daily_usage: float
    lead_time_days: int

@app.get("/")
def read_root():
    return {"message": "Advanced Pharmacy AI is Ready! 🚀"}

@app.post("/add_medication/")
def add_medication(med: MedicationCreate, db: Session = Depends(get_db)):
    new_med = models.Medication(
        name=med.name, category=med.category,
        current_stock=med.current_stock, price=med.price,
        min_stock=med.min_stock, daily_usage=med.daily_usage,
        lead_time_days=med.lead_time_days
    )
    db.add(new_med)
    db.commit()
    db.refresh(new_med)
    return {"message": "✅ تم إضافة الدواء بنجاح!", "medication": new_med}

@app.get("/predict/{med_id}")
def predict_shortage(med_id: int, db: Session = Depends(get_db)):
    med = db.query(models.Medication).filter(models.Medication.id == med_id).first()
    if not med:
        raise HTTPException(status_code=404, detail="❌ الدواء مش موجود!")

    # 1. تجهيز الـ Features
    current_date = datetime.datetime.now()
    month = current_date.month
    
    if month in [12, 1, 2]: season = 0
    elif month in [3, 4, 5]: season = 1
    elif month in [6, 7, 8]: season = 2
    else: season = 3
    
    temporal_score = ((month * 20) + (season * 20) + ((month * season) * 5)) * 100
    month_sin = np.sin(2 * np.pi * (month / 12.0))
    month_cos = np.cos(2 * np.pi * (month / 12.0))
    
    stock_gap = med.current_stock - med.min_stock
    consumption_pressure = med.daily_usage * med.lead_time_days
    
    features = pd.DataFrame([{
        'temporal_score': temporal_score,
        'month_sin': month_sin,
        'month_cos': month_cos,
        'month': month,
        'season_encoded': season,
        'current_stock': med.current_stock,
        'daily_usage': med.daily_usage,
        'lead_time_days': med.lead_time_days,
        'stock_gap': stock_gap,
        'consumption_pressure': consumption_pressure
    }])

    # 2. التوقع
    probability = ml_model.predict_proba(features)[0][1]
    
    is_shortage = bool(probability > 0.3)
    status = "Critical Warning" if is_shortage else "Safe"

    return {
        "medication_id": med.id, # زودتلك الـ ID هنا عشان هنحتاجه في فلاتر
        "medication_name": med.name,
        "current_stock": med.current_stock,
        "shortage_probability": f"{probability:.1%}",
        "status": status,
        "message": "⚠️ الدواء هينقص خلال أسبوع!" if is_shortage else "✅ المخزون آمن لأكتر من أسبوع."
    }

# ==========================================
# المسار الجديد: سحب كل الأدوية عشان نعرضها في شاشة فلاتر
# ==========================================
@app.get("/medications/")
def get_all_medications(db: Session = Depends(get_db)):
    medications = db.query(models.Medication).all()
    return medications
@app.delete("/delete_medication/{med_id}")
def delete_medication(med_id: int, db: Session = Depends(get_db)):
    # بندور على الدواء بالـ ID بتاعه
    med = db.query(models.Medication).filter(models.Medication.id == med_id).first()
    
    if not med:
        raise HTTPException(status_code=404, detail="الدواء غير موجود")
        
    # بنمسح الدواء ونحفظ التعديل
    db.delete(med)
    db.commit()
    return {"message": "🗑️ تم حذف الدواء بنجاح"}

@app.put("/sell_medication/{med_id}")
def sell_medication(med_id: int, sale: SellMedication, db: Session = Depends(get_db)):
    # 1. البحث عن الدواء في قاعدة البيانات باستخدام الـ ID
    med = db.query(models.Medication).filter(models.Medication.id == med_id).first()
    
    # 2. التأكد من وجود الدواء
    if not med:
        raise HTTPException(status_code=404, detail="عذراً، هذا الدواء غير مسجل!")
    
    # 3. فحص الأمان: هل المخزن يكفي للبيع؟
    if med.current_stock < sale.quantity:
        raise HTTPException(
            status_code=400, 
            detail=f"الكمية لا تكفي! المتاح فقط {med.current_stock} علبة."
        )
        
    # 4. عملية الخصم الحسابية
    med.current_stock -= sale.quantity
    
    # 5. حفظ التعديل النهائي في قاعدة البيانات
    db.commit()
    
    return {"message": "✅ تمت عملية البيع بنجاح", "remaining_stock": med.current_stock}