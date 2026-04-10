# ==============================
# 1. Import Libraries
# ==============================
import pandas as pd
import numpy as np

from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix

# ==============================
# 2. Load Data
# ==============================
df = pd.read_csv("extended_drug_shortage_data_rounded.csv")

# ==============================
# 3. Preprocessing
# ==============================
df['date'] = pd.to_datetime(df['date'])

# Ensure month is present from date
if 'month' not in df.columns:
    df['month'] = df['date'].dt.month

# Ensure season is present or derive from month
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

# Day of week can be available if needed
if 'day_of_week' not in df.columns:
    df['day_of_week'] = df['date'].dt.dayofweek

# ==============================
# 4. Feature Engineering
# ==============================
df['stock_gap'] = df['current_stock'] - df['min_stock']
df['consumption_pressure'] = df['daily_usage'] * df['lead_time_days']

# Encode the season
df['season_encoded'] = df['season'].map({'Winter': 0, 'Spring': 1, 'Summer': 2, 'Autumn': 3})

# Give month and season high influence with a single combined temporal score
# (not separated, one strong feature dominates temporal impact)
month_weight = 20
season_weight = 20
df['month_weighted'] = df['month'] * month_weight
df['season_weighted'] = df['season_encoded'] * season_weight

df['month_season_int'] = df['month'] * df['season_encoded']

df['temporal_score'] = df['month_weighted'] + df['season_weighted'] + (df['month_season_int'] * 5)

# Amplify temporal importance strongly
# (make the combined temporal score much larger so trees prefer splits on it)
df['temporal_score'] = df['temporal_score'] * 100

# Periodic transformations for month to capture cyclical effects
# (keep as auxiliary features)
df['month_sin'] = np.sin(2 * np.pi * (df['month'] / 12.0))
df['month_cos'] = np.cos(2 * np.pi * (df['month'] / 12.0))

# ==============================
# 5. New Target (Future Prediction)
# ==============================

# Number of days to predict ahead
future_days = 7

# Calculate stock after 7 days
df['future_stock'] = df['current_stock'] - (df['daily_usage'] * future_days)

# Will there be a shortage?
df['future_shortage'] = df['future_stock'] < df['min_stock']

# ==============================
# 6. Features & Target
# ==============================
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

# ==============================
# 7. Split
# ==============================
X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,
    random_state=42,
    stratify=y
)

# ==============================
# 8. Model
# ==============================
model = RandomForestClassifier(
    class_weight={False: 1, True: 2},
    random_state=42
)

model.fit(X_train, y_train)

# Save the trained model
import joblib
joblib.dump(model, 'drug_shortage_model.pkl')
print("Model saved as drug_shortage_model.pkl")

# ==============================
# 9. Prediction (Threshold)
# ==============================
probs = model.predict_proba(X_test)[:, 1]

threshold = 0.3
pred = (probs > threshold).astype(int)

# ==============================
# 10. Evaluation
# ==============================
print("=== Classification Report ===")
print(classification_report(y_test, pred))

print("\n=== Confusion Matrix ===")
print(confusion_matrix(y_test, pred))

# ==============================
# 11. Feature Importance
# ==============================
importance = pd.Series(model.feature_importances_, index=features)
importance = importance.sort_values(ascending=False)

print("\n=== Feature Importance ===")
for feature, imp in importance.items():
    print(f"{feature}: {imp:.1%}")

# Optional: Plot if matplotlib available
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