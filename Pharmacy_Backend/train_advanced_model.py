import pandas as pd
import numpy as np

from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix

df = pd.read_csv("extended_drug_shortage_data_rounded.csv")

df['date'] = pd.to_datetime(df['date'])

if 'month' not in df.columns:
    df['month'] = df['date'].dt.month

if 'season' not in df.columns:
    def get_season(month):
        if month in [12, 1, 2]:
            return 'Winter'
        elif month in [3, 4, 5]:
            return 'Spring'
        elif month in [6, 7, 8]:
            return 'Summer'
        else:
            return 'Autumn'
    df['season'] = df['month'].apply(get_season)

if 'day_of_week' not in df.columns:
    df['day_of_week'] = df['date'].dt.dayofweek

df['stock_gap'] = df['current_stock'] - df['min_stock']
df['consumption_pressure'] = df['daily_usage'] * df['lead_time_days']

df['season_encoded'] = df['season'].map({'Winter': 0, 'Spring': 1, 'Summer': 2, 'Autumn': 3})

month_weight = 20
season_weight = 20
df['month_weighted'] = df['month'] * month_weight
df['season_weighted'] = df['season_encoded'] * season_weight

df['month_season_int'] = df['month'] * df['season_encoded']

df['temporal_score'] = df['month_weighted'] + df['season_weighted'] + (df['month_season_int'] * 5)

df['temporal_score'] = df['temporal_score'] * 100

df['month_sin'] = np.sin(2 * np.pi * (df['month'] / 12.0))
df['month_cos'] = np.cos(2 * np.pi * (df['month'] / 12.0))


future_days = 7

df['future_stock'] = df['current_stock'] - (df['daily_usage'] * future_days)

df['future_shortage'] = df['future_stock'] < df['min_stock']

features = [
    'temporal_score',
    'month_sin',
    'month_cos',
    'month',
    'season_encoded',
    'current_stock',
    'daily_usage',
    'lead_time_days',
    'stock_gap',
    'consumption_pressure'
]

X = df[features]
y = df['future_shortage']

X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,
    random_state=42,
    stratify=y
)

model = RandomForestClassifier(
    class_weight={False: 1, True: 2},
    random_state=42
)

model.fit(X_train, y_train)

import joblib
joblib.dump(model, 'drug_shortage_model.pkl')
print("Model saved as drug_shortage_model.pkl")

probs = model.predict_proba(X_test)[:, 1]

threshold = 0.3
pred = (probs > threshold).astype(int)

print("=== Classification Report ===")
print(classification_report(y_test, pred))

print("\n=== Confusion Matrix ===")
print(confusion_matrix(y_test, pred))

importance = pd.Series(model.feature_importances_, index=features)
importance = importance.sort_values(ascending=False)

print("\n=== Feature Importance ===")
for feature, imp in importance.items():
    print(f"{feature}: {imp:.1%}")

try:
    import matplotlib.pyplot as plt
    plt.figure(figsize=(10, 6))
    importance.plot(kind='bar')
    plt.title('Feature Importance')
    plt.ylabel('Importance')
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig('feature_importance.png')
    print("Feature importance plot saved as feature_importance.png")
except ImportError:
    print("Matplotlib not available for plotting.")