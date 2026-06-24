import '../models/dashboard_models.dart'; 

abstract class IDashboardService {
  
  Future<DashboardData> getDashboardData();

  
  Future<bool> addMedication(Map<String, dynamic> drugData);
  
  Future<bool> updateMedication(int id, Map<String, dynamic> drugData);
  
  Future<bool> deleteMedication(int id);
  Future<SmartPrediction?> getAiPrediction(int medId);

  Future<bool> sellMedication(int id, int quantity);
}
