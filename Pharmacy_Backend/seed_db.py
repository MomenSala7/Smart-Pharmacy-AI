import pandas as pd
from database import SessionLocal
import models

def seed_database():
    db = SessionLocal()
    print("⏳ بنقرأ ملف الـ CSV... ثواني ويكون جاهز!")
    
    try:
        # قراءة الملف اللي فيه الداتا
        df = pd.read_csv("extended_drug_shortage_data_rounded.csv")
        
        # هناخد دواء واحد من كل نوع عشان منكررش الأدوية (بافتراض إن عمود الاسم اسمه name)
        # لو الملف مفيش فيه عمود اسم الدواء، هنولد أسماء افتراضية للتجربة
        if 'name' in df.columns:
            unique_drugs = df.drop_duplicates(subset=['name'])
        else:
            # لو الداتا بتاعتكم مفهاش أسماء أدوية صريحة، هناخد أول 50 صف كأدوية مختلفة
            unique_drugs = df.head(50).copy()
            unique_drugs['name'] = [f"Medication_{i}" for i in range(1, 51)]
            unique_drugs['category'] = "General"
            unique_drugs['price'] = 50.0
            
        added_count = 0
        for index, row in unique_drugs.iterrows():
            # التأكد إن الدواء مش موجود أصلاً عشان منعملش تكرار
            existing_med = db.query(models.Medication).filter(models.Medication.name == row['name']).first()
            
            if not existing_med:
                new_med = models.Medication(
                    name=row['name'],
                    category=row.get('category', 'General'),
                    current_stock=int(row.get('current_stock', 10)),
                    price=float(row.get('price', 50.0)),
                    min_stock=int(row.get('min_stock', 5)),
                    daily_usage=float(row.get('daily_usage', 1.0)),
                    lead_time_days=int(row.get('lead_time_days', 2))
                )
                db.add(new_med)
                added_count += 1
        
        db.commit()
        print(f"✅ تمت المهمة بنجاح! ضفنا {added_count} دواء جديد لقاعدة البيانات.")
    
    except Exception as e:
        print(f"❌ حصلت مشكلة: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()