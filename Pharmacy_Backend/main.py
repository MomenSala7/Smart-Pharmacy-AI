# ==========================================
# 1. استدعاء المكتبات (Imports)
# ==========================================
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from pydantic import BaseModel

import pandas as pd
import numpy as np
import datetime
import joblib

# استدعاء ملفات الداتابيز بتاعتنا
import models
from database import engine, SessionLocal

# ==========================================
# 2. إعدادات السيرفر وقاعدة البيانات
# ==========================================
# إنشاء الجداول في الداتابيز لو مش موجودة
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Pharmacy Shortage Prediction System 🚀")

# إضافة إعدادات الـ CORS عشان الفرونت إند (فلاتر) يعرف يكلم السيرفر بدون مشاكل أمنية
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==========================================
# 3. تحميل موديل الذكاء الاصطناعي (Prophet)
# ==========================================
# بنحمل الموديل مرة واحدة بس أول ما السيرفر يشتغل عشان منبطأش النظام
try:
    ml_model = joblib.load('shortage_model.joblib')
    print("✅ AI Model (Prophet) loaded successfully!")
except Exception as e:
    print(f"❌ Error loading AI model: {e}")
    ml_model = None

# دالة مساعدة لفتح وقفل الاتصال بالداتابيز مع كل ريكويست
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ==========================================
# 4. نماذج البيانات (Pydantic Models) - اللي بنستقبلها من فلاتر
# ==========================================
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

# ==========================================
# 5. مسارات الـ API (Endpoints)
# ==========================================

@app.get("/")
def read_root():
    """مسار اختبار السيرفر"""
    return {"message": "Advanced Pharmacy AI is Ready! 🚀"}

@app.post("/add_medication/")
def add_medication(med: MedicationCreate, db: Session = Depends(get_db)):
    """إضافة دواء جديد لقاعدة البيانات"""
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

@app.get("/medications/")
def get_all_medications(db: Session = Depends(get_db)):
    """سحب كل الأدوية عشان نعرضها في شاشة فلاتر (الداشبورد)"""
    medications = db.query(models.Medication).all()
    return medications

@app.delete("/delete_medication/{med_id}")
def delete_medication(med_id: int, db: Session = Depends(get_db)):
    """حذف دواء من قاعدة البيانات باستخدام الـ ID بتاعه"""
    med = db.query(models.Medication).filter(models.Medication.id == med_id).first()
    
    if not med:
        raise HTTPException(status_code=404, detail="❌ الدواء غير موجود")
        
    db.delete(med)
    db.commit()
    return {"message": "🗑️ تم حذف الدواء بنجاح"}

@app.put("/sell_medication/{med_id}")
def sell_medication(med_id: int, sale: SellMedication, db: Session = Depends(get_db)):
    """عملية الكاشير: بيع دواء وخصم الكمية من المخزن"""
    med = db.query(models.Medication).filter(models.Medication.id == med_id).first()
    
    if not med:
        raise HTTPException(status_code=404, detail="عذراً، هذا الدواء غير مسجل!")
    
    # فحص الأمان: هل المخزن يكفي للبيع؟
    if med.current_stock < sale.quantity:
        raise HTTPException(
            status_code=400, 
            detail=f"الكمية لا تكفي! المتاح فقط {med.current_stock} علبة."
        )
        
    # عملية الخصم الحسابية
    med.current_stock -= sale.quantity
    db.commit()
    
    return {"message": "✅ تمت عملية البيع بنجاح", "remaining_stock": med.current_stock}

# ==========================================
# 6. الذكاء الاصطناعي - التنبؤ بالنواقص (Prophet Integration)
# ==========================================
@app.get("/predict/{med_id}")
def predict_shortage(med_id: int, db: Session = Depends(get_db)):
    """تحليل الذكاء الاصطناعي: دمج تريند السوق العام مع أرقام الدواء الفعلي"""
    
    # 1. البحث عن الدواء
    med = db.query(models.Medication).filter(models.Medication.id == med_id).first()
    if not med:
        raise HTTPException(status_code=404, detail="❌ الدواء مش موجود!")

    if ml_model is None:
        raise HTTPException(status_code=500, detail="❌ الموديل غير متاح حالياً")

    try:
        # 2. تجهيز تواريخ المستقبل (هنسأل الموديل عن الـ 7 أيام الجايين)
        current_date = datetime.datetime.now()
        future_dates = pd.DataFrame({
            'ds': pd.date_range(start=current_date, periods=7)
        })

        # 3. استدعاء الموديل لمعرفة تريند السوق (النزول أو الصعود العام)
        forecast = ml_model.predict(future_dates)
        predicted_trend = forecast['yhat'].values
        
        # 4. حساب نسبة النزول المتوقعة في السوق
        start_stock = predicted_trend[0]
        end_stock = predicted_trend[-1]
        
        trend_drop_percentage = 0
        if start_stock > 0 and end_stock < start_stock:
            trend_drop_percentage = (start_stock - end_stock) / start_stock

        # 5. حساب الضغط الفعلي على هذا الدواء تحديداً
        if med.current_stock > 0:
            drug_pressure = (med.daily_usage * 7) / med.current_stock
        else:
            drug_pressure = 1.0 # المخزون صفر أصلاً

        # 6. دمج تريند الذكاء الاصطناعي مع حالة الدواء الحالية (المعادلة السحرية)
        if med.current_stock <= med.min_stock:
            # لو الدواء تحت الحد الأدنى، الخطر عالي جداً وبنزود عليه تريند السوق
            probability = 0.85 + trend_drop_percentage 
        else:
            # لو الدواء فيه مخزون، بنحسب نسبة الخطر بناءً على ضغط السحب والتريند
            probability = drug_pressure + (trend_drop_percentage * 0.5)

        # تحجيم النسبة عشان متعديش 100% (0.99) ولا تقل عن 1% (0.01)
        probability = min(0.99, max(0.01, probability))

        # اتخاذ القرار
        is_shortage = bool(probability > 0.4)
        status = "Critical Warning" if is_shortage else "Safe"

        return {
            "medication_id": med.id,
            "medication_name": med.name,
            "current_stock": med.current_stock,
            "shortage_probability": f"{probability:.1%}",
            "status": status,
            "message": "⚠️ الذكاء الاصطناعي يتوقع نقص الدواء قريباً!" if is_shortage else "✅ المخزون والمؤشرات المستقبلية آمنة."
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI Prediction Error: {str(e)}")