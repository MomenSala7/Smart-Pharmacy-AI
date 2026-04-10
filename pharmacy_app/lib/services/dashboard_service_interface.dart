import '../models/dashboard_models.dart'; 

abstract class IDashboardService {
  // دالة بتجيب كل بيانات الداشبورد (القديمة)
  Future<DashboardData> getDashboardData();

  // --- الدوال الجديدة لإدارة الأدوية (CRUD) ---
  
  // دالة لإضافة دواء جديد (POST)
  Future<bool> addMedication(Map<String, dynamic> drugData);
  
  // دالة لتعديل دواء موجود عن طريق الـ ID (PUT)
  Future<bool> updateMedication(int id, Map<String, dynamic> drugData);
  
  // دالة لحذف دواء عن طريق الـ ID (DELETE)
  Future<bool> deleteMedication(int id);
  // دالة جديدة لاستدعاء توقعات الذكاء الاصطناعي لدواء معين
  Future<SmartPrediction?> getAiPrediction(int medId);

  // السطر الجديد بتاع الكاشير (البيع)
  Future<bool> sellMedication(int id, int quantity);
}
