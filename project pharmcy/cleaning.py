import pandas as pd
data=pd.read_csv("drug_shortage_dataset.csv")

print(data.info())
print(data.head())

data['date']=pd.to_datetime(data['date'])

print(data.isnull().sum())

print(data.duplicated().sum())

text_columns=['facility_name','facility_type','location','drug_name','category']
for col in text_columns:

    data[col]=data[col].str.strip()

    data[col]=data[col].str.lower()
    
    
print(data.describe())

numric_cols=['daily_usage','lead_time_days','current_stock','min_stock']

for col in numric_cols:
    Q1=data[col].quantile(0.25)
    Q3=data[col].quantile(0.75)
    IQR=Q3-Q1

    lower=Q1-1.5*IQR
    upper=Q3+1.5*IQR
    outliers=data[(data[col]<lower)|(data[col]>upper)]

    print(f"\nعمود: {col}")
print(f"عدد القيم الشاذة: {len(outliers)}")
print(outliers[[col]])

data.to_csv("cleaned_drug_dataset.csv",index=False)
print("\nتم حفظ الداتا بعد التنظيف!")

data['expected_usage']=data['daily_usage']*data['lead_time_days']

data['stock_after_lead_time']=data['current_stock']-data['expected_usage']

data['shortage_flag']=data['stock_after_lead_time']<0

print(data.head())

data.to_csv("cleaned_drug_shortage_data2.csv",index=False)
