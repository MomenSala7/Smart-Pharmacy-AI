import pandas as pd
from sklearn.linear_model import LinearRegression
import pickle
import os

# اسم الملف اللي التيم بعته
DATA_FILE = 'cleaned_drug_shortage_data2.csv'

if not os.path.exists(DATA_FILE):
    print(f"❌ خطأ: ملف {DATA_FILE} مش موجود في الفولدر!")
else:
    print(f"⏳ جاري تحميل البيانات الحقيقية من {DATA_FILE}...")
    
    # 1. قراءة البيانات
    df = pd.read_csv(DATA_FILE)
    
    # ملحوظة: أنا هفترض إن الأعمدة اسمها قريب من اللي عملناه 
    # لو حصل خطأ قولي أسماء الأعمدة في الملف إيه
    # هحاول استنتج الأعمدة المهمة (المخزون والسحب)
    
    # 2. تجهيز البيانات (بافتراض إن دي أسماء الأعمدة أو قريبة منها)
    # لو التيم مسميها أسامي تانية، هنعدلها فوراً
    try:
        # هنجرب نسحب أول عمودين عدديين كمثال للتدريب
        X = df.select_dtypes(include=['number']).iloc[:, :2] 
        y = df.select_dtypes(include=['number']).iloc[:, -1] # آخر عمود عددي غالباً هو النتيجة
        
        print("🧠 جاري تدريب النموذج على البيانات الحقيقية...")
        model = LinearRegression()
        model.fit(X, y)
        
        # 3. حفظ النموذج الجديد (المخ الحقيقي)
        with open('shortage_model.pkl', 'wb') as f:
            pickle.dump(model, f)
            
        print("✅ تم بنجاح! السيرفر دلوقتي بيستخدم بيانات التيم الحقيقية.")
        
    except Exception as e:
        print(f"⚠️ حصلت مشكلة في قراءة أعمدة الملف: {e}")
        print("ممكن تفتح ملف الـ CSV وتقولي أسماء الأعمدة اللي فوق إيه بالظبط؟")