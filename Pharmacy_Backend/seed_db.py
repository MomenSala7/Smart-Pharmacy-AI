import pandas as pd
import random 
from database import SessionLocal, engine
import models

models.Base.metadata.create_all(bind=engine)

REAL_DRUGS = [
    "Panadol Extra", "Augmentin 1g", "Brufen 400mg", "Congestal", "Concor 5mg",
    "Ketofan 50mg", "Cataflam 50mg", "Amaryl 2mg", "Glucophage 1000mg", "Eltroxin 50mcg",
    "Antinal Capsule", "Flagyl 500mg", "Nexium 40mg", "Controloc 40mg", "Zyrtec 10mg",
    "Telfast 120mg", "Lasix 40mg", "Capoten 25mg", "Aldomet 250mg", "Aspirin Protect 100",
    "Plavix 75mg", "Lipitor 20mg", "Crestor 10mg", "Ventolin Inhaler", "Symbicort Turbuhaler",
    "Voltaren 50mg", "Mobitil 15mg", "Alphintern", "Amoxil 500mg", "Zithromax 500mg",
    "Cipro 500mg", "Tavanic 500mg", "Doxycost 100mg", "Neurontin 300mg", "Lyrica 75mg",
    "Tegretol 200mg", "Depakine Chrono", "Lustral 50mg", "Cipralex 10mg", "Panadol Cold&Flu",
    "Otrivin Spray", "Betadine Gargle", "Rennie Tablets", "Gaviscon Syrup", "Maalox Plus",
    "Motilium 10mg", "Primperan", "Colona", "Spasmo-Digestin", "Visine Drops"
]

CATEGORIES = ["Painkillers", "Antibiotics", "Chronic", "Allergy", "Digestive", "Cardiovascular"]

def seed_database():
    db = SessionLocal()
    print("⏳ بنقرأ ملف الـ CSV وبنجهز الأدوية الحقيقية للصيدلية... ثواني ويكون جاهز!")
    
    try:
        df = pd.read_csv("extended_drug_shortage_data_rounded.csv")
        
        unique_drugs = df.head(50).copy()
        actual_count = len(unique_drugs)
        
        unique_drugs['name'] = REAL_DRUGS[:actual_count]
        unique_drugs['category'] = [random.choice(CATEGORIES) for _ in range(actual_count)]
        unique_drugs['price'] = [round(random.uniform(15.0, 300.0), 2) for _ in range(actual_count)]
            
        added_count = 0
        for index, row in unique_drugs.iterrows():
            brand_name_val = row['name']
            
            existing_product = db.query(models.Product).filter(models.Product.brand_name == brand_name_val).first()
            
            if not existing_product:
                new_product = models.Product(
                    brand_name=brand_name_val,
                    category=row['category'],
                    unit_price=float(row['price'])
                )
                db.add(new_product)
                db.flush()  
                
                new_inventory = models.Inventory(
                    product_id=new_product.id,
                    stock_level=int(row.get('current_stock', 10)), 
                    min_stock=int(row.get('min_stock', 5)),
                    daily_usage=float(row.get('daily_usage', 1.0)),
                    lead_time_days=int(row.get('lead_time_days', 2))
                )
                db.add(new_inventory)
                added_count += 1
        
        db.commit()
        print(f"✅ تمت المهمة بنجاح! ضفنا {added_count} دواء حقيقي للمخزن.")
    
    except Exception as e:
        db.rollback() 
        print(f"❌ حصلت مشكلة: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()