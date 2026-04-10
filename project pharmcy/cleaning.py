#استيراد المكتبات وقراءة البيانات
#-----------------------------------------------------
import pandas as pd
data=pd.read_csv("drug_shortage_dataset.csv")
#------------------------------------------------------
#فحص البيانات الاساسية
#------------------------------------------------------
print(data.info())
print(data.head())
#------------------------------------------------------
#تحويل عمود التاريخ من نص الي (datetime)
data['date']=pd.to_datetime(data['date'])
#------------------------------------------------------
#التأكد من عدم وجود قيم مفقودة
print(data.isnull().sum())
#التأكد من عدم وجود تكرار
print(data.duplicated().sum())
#------------------------------------------------------
#تنظيف الاعمدة النصية
text_columns=['facility_name','facility_type','location','drug_name','category']
for col in text_columns:
    #ازاله المسافات الزائدة
    data[col]=data[col].str.strip()
    #تحويل النص لحروف صغيرة
    data[col]=data[col].str.lower()
    #---------------------------------------------------
    #التاكد من عدم وجود قيم شاذة
print(data.describe())
#تحديد الاعمدة الرقمية
numric_cols=['daily_usage','lead_time_days','current_stock','min_stock']
#فحص كل عمود
for col in numric_cols:
    Q1=data[col].quantile(0.25)
    Q3=data[col].quantile(0.75)
    IQR=Q3-Q1
    #تحديد الحد الادني والاقصي
    lower=Q1-1.5*IQR
    upper=Q3+1.5*IQR
    outliers=data[(data[col]<lower)|(data[col]>upper)]
    #عرض النتيجة
    print(f"\nعمود: {col}")
print(f"عدد القيم الشاذة: {len(outliers)}")
print(outliers[[col]])
#-----------------------------------------------------
#حفظ الداتا بعد التنظيف
data.to_csv("cleaned_drug_dataset.csv",index=False)
print("\nتم حفظ الداتا بعد التنظيف!")
#---------------------------------------------
#Feature Engineering
#-----------------------------------------
#حساب الاستهلاك المتوقع خلال فترة التوريد 
data['expected_usage']=data['daily_usage']*data['lead_time_days']
#-------------------------------------------
#لحساب هل المخزون سيكفي حتي وصول الشحنة ام لا
#-----------------------------------------------------
#-----------------------------------------------------
#حساب المخزون المتوقع بعد فترة التوريد
data['stock_after_lead_time']=data['current_stock']-data['expected_usage']
#لحساب هل المخزون سيكفي حتي وصول الشحنة القادمة
#----------------------------------------------------------
#----------------------------------------------------------
#هل سيحدث نقص في الدواء
data['shortage_flag']=data['stock_after_lead_time']<0
#لو الناتجTrue سيحدث نقص 
#لو false المخزون كافي
print(data.head())
#حفظ الداتا بعد ال Feature
data.to_csv("cleaned_drug_shortage_data2.csv",index=False)
