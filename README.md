# Smart Pharmacy AI Dashboard

A Full-Stack, AI-powered inventory management and point-of-sale (POS) system designed for pharmacies. This dashboard integrates a Flutter frontend with a FastAPI backend and a Machine Learning model to predict medication shortages in real-time.

## Key Features
* **Real-time Inventory Management:** Perform full CRUD operations (Add, View, Update, Delete) on medications.
* **Smart POS (Point of Sale):** Interactive cashier system that dynamically updates stock upon sales.
* **AI Shortage Prediction:** Integrated Machine Learning model (Scikit-learn) that predicts medication shortages based on temporal data, daily usage, and lead time.
* **Dynamic Data Visualization:** Interactive pie charts for stock status and line charts for 6-month sales trends.
* **Clean Architecture:** Modular Flutter codebase (Widgets separated) and robust FastAPI backend.

## 🛠️ Tech Stack
* **Frontend:** Flutter (Dart), FL Chart (for data visualization)
* **Backend:** FastAPI (Python), SQLAlchemy (ORM), SQLite (Database)
* **Machine Learning:** Scikit-learn, Pandas, NumPy, Joblib

## 🚀 Getting Started

### 1. Backend Setup (FastAPI & ML)
```bash
cd Pharmacy_Backend
# Create and activate virtual environment
python -m venv venv
source venv/bin/activate  # On Windows use `venv\Scripts\activate`

# Install dependencies
pip install fastapi uvicorn sqlalchemy pydantic pandas numpy scikit-learn joblib

# Run the server
uvicorn main:app --reload