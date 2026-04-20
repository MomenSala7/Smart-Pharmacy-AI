import pandas as pd
from database import SessionLocal
import models

def seed_database():
    db = SessionLocal()
    print("⏳ بنقرأ ملف الـ CSV وبنجهز الداتا للجدولين... ثواني ويكون جاهز!")
    
    try:
        # قراءة الملف اللي فيه الداتا
        df = pd.read_csv("extended_drug_shortage_data_rounded.csv")
        
        # هناخد دواء واحد من كل نوع عشان منكررش الأدوية
        if 'name' in df.columns:
            unique_drugs = df.drop_duplicates(subset=['name'])
        else:
            unique_drugs = df.head(50).copy()
            unique_drugs['name'] = [f"Medication_{i}" for i in range(1, 51)]
            unique_drugs['category'] = "General"
            unique_drugs['price'] = 50.0
            
        added_count = 0
        for index, row in unique_drugs.iterrows():
            brand_name_val = row['name']
            
            # التأكد إن الدواء مش موجود أصلاً في جدول المنتجات
            existing_product = db.query(models.Product).filter(models.Product.brand_name == brand_name_val).first()
            
            if not existing_product:
                # 1. إنشاء المنتج في جدول (Product)
                new_product = models.Product(
                    brand_name=brand_name_val,
                    category=row.get('category', 'General'),
                    unit_price=float(row.get('price', 50.0))
                )
                db.add(new_product)
                db.flush()  # بنعمل flush عشان الداتابيز تدي للمنتج ID نقدر نستخدمه في المخزون
                
                # 2. إنشاء المخزون المرتبط بيه في جدول (Inventory)
                new_inventory = models.Inventory(
                    product_id=new_product.id, # ربطنا المخزون بالمنتج
                    stock_level=int(row.get('current_stock', 10)), 
                    min_stock=int(row.get('min_stock', 5)),
                    daily_usage=float(row.get('daily_usage', 1.0)),
                    lead_time_days=int(row.get('lead_time_days', 2))
                )
                db.add(new_inventory)
                added_count += 1
        
        db.commit()
        print(f"✅ تمت المهمة بنجاح! ضفنا {added_count} دواء جديد (موزعين على جدولين المنتجات والمخزون).")
    
    except Exception as e:
        db.rollback() # لو حصلت مشكلة نلغي العملية عشان الداتابيز متبوظش
        print(f"❌ حصلت مشكلة: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()