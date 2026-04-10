// 1. موديل الكروت الرئيسية (Top Summary Cards)
class DashboardSummary {
  final int totalDrugs;
  final int availableDrugs;
  final int lowStockDrugs;
  final int outOfStock;
  final int predictedShortage;

  DashboardSummary({
    required this.totalDrugs,
    required this.availableDrugs,
    required this.lowStockDrugs,
    required this.outOfStock,
    required this.predictedShortage,
  });
}

// 2. موديل الرسوم البيانية (Charts) - مثال للـ Pie Chart
class StockPercentage {
  final double available; // مثلاً 70.0
  final double lowStock;  // مثلاً 20.0
  final double outOfStock; // مثلاً 10.0

  StockPercentage({
    required this.available,
    required this.lowStock,
    required this.outOfStock,
  });
}

// 3. موديل التنبيهات (Alerts)
class DrugAlert {
  final String drugName;
  final String message;
  final String alertType; // 'out_of_stock' (Red), 'low_stock' (Yellow), 'predicted' (Blue)
  
  DrugAlert({
    required this.drugName,
    required this.message,
    required this.alertType,
  });
}

// 4. موديل جدول آخر التحديثات (Recent Drugs Table)
class RecentDrug {
  final int id;
  final String drugName;
  final String companyName;
  final String status;
  final String dateUpdated;

  RecentDrug({
    required this.id,
    required this.drugName,
    required this.companyName,
    required this.status,
    required this.dateUpdated,
  });
}

// 5. موديل الذكاء الاصطناعي (Smart AI Predictions)
class SmartPrediction {
  final String drugName;
  final String expectedShortageDate; // أمتى متوقع ينقص
  final double confidenceLevel; // دقة التوقع (مثلاً 95%)
  final String recommendation; // اقتراح لحل المشكلة

  SmartPrediction({
    required this.drugName,
    required this.expectedShortageDate,
    required this.confidenceLevel,
    required this.recommendation,
  });
}

// 6. الموديل الشامل اللي هيجمع كل ده ويبعته للشاشة مرة واحدة
class DashboardData {
  final DashboardSummary summary;
  final StockPercentage stockPercent;
  final List<DrugAlert> alerts;
  final List<RecentDrug> recentDrugs;
  final List<SmartPrediction> aiPredictions;

  DashboardData({
    required this.summary,
    required this.stockPercent,
    required this.alerts,
    required this.recentDrugs,
    required this.aiPredictions,
  });
}