import pandas as pd
from sklearn.linear_model import LinearRegression
import pickle
import os

DATA_FILE = 'cleaned_drug_shortage_data2.csv'

if not os.path.exists(DATA_FILE):
    print(f"❌ خطأ: ملف {DATA_FILE} مش موجود في الفولدر!")
else:
    print(f"⏳ جاري تحميل البيانات الحقيقية من {DATA_FILE}...")
    
    df = pd.read_csv(DATA_FILE)
    
    try:
        X = df.select_dtypes(include=['number']).iloc[:, :2] 
        y = df.select_dtypes(include=['number']).iloc[:, -1]
        
        print(" جاري تدريب النموذج على البيانات الحقيقية...")
        model = LinearRegression()
        model.fit(X, y)
        
        with open('shortage_model.pkl', 'wb') as f:
            pickle.dump(model, f)
            
        print("✅ تم بنجاح! السيرفر دلوقتي بيستخدم بيانات التيم الحقيقية.")
        
    except Exception as e:
        print(f"⚠️ حصلت مشكلة في قراءة أعمدة الملف: {e}")
        print("ممكن تفتح ملف الـ CSV وتقولي أسماء الأعمدة اللي فوق إيه بالظبط؟")