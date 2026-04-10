import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_models.dart';
import 'dashboard_service_interface.dart';

class ApiDashboardService implements IDashboardService {
  // استخدمنا نفس الرابط اللي شغال على بورت 8000
  static const String baseUrl = 'http://127.0.0.1:8000';

  @override
  Future<DashboardData> getDashboardData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/medications/'));

      if (response.statusCode == 200) {
        // استخدمنا طريقه ممتازة لفك التشفير عشان العربي يظهر مظبوط
        List<dynamic> meds = json.decode(utf8.decode(response.bodyBytes));

        // السطر السحري الجديد: هنعكس القائمة عشان أجدد دواء يجي في الأول
        meds = meds.reversed.toList();

        // --- 1. حساب الإحصائيات (Summary) ---
        int total = meds.length;
        int available = 0;
        int lowStock = 0;
        int outOfStock = 0;
        
        List<DrugAlert> alerts = [];
        List<RecentDrug> recentDrugs = [];

        // بنلف على كل دواء عشان نصنفه ونحسب الإحصائيات
        for (var med in meds) {
          int id = med['id'] ?? 0; // التعديل الأول: استخراج الـ ID
          int currentStock = med['current_stock'] ?? 0;
          int minStock = med['min_stock'] ?? 10;
          String name = med['name'] ?? 'غير معروف';
          String company = med['company'] ?? 'غير معروفة'; // لو عندك حقل اسم الشركة في الداتا بيز، أو ممكن تحط category
          String lastUpdated = med['last_updated'] ?? DateTime.now().toString().substring(0, 10);

          // التقييم للتنبيهات
          if (currentStock == 0) {
            outOfStock++;
            alerts.add(DrugAlert(drugName: name, message: 'نفد تماماً من المخزن', alertType: 'out_of_stock'));
          } else if (currentStock <= minStock) {
            lowStock++;
            alerts.add(DrugAlert(drugName: name, message: 'الكمية المتبقية قليلة ($currentStock فقط)', alertType: 'low_stock'));
          } else {
            available++;
          }

          // إضافة الدواء لجدول التحديثات (هناخذ أول 5 مثلاً كعينة حديثة)
          if (recentDrugs.length < 5) {
             recentDrugs.add(RecentDrug(
              id: id, // التعديل التاني: إضافة الـ ID للموديل
              drugName: name,
              companyName: company,
              status: currentStock == 0 ? 'Out of Stock' : (currentStock <= minStock ? 'Low Stock' : 'Available'),
              dateUpdated: lastUpdated,
            ));
          }
        }

        // --- 2. حساب النسب المئوية للـ Pie Chart ---
        double availablePercent = total > 0 ? (available / total) * 100 : 0;
        double lowStockPercent = total > 0 ? (lowStock / total) * 100 : 0;
        double outOfStockPercent = total > 0 ? (outOfStock / total) * 100 : 0;

        // --- 3. بيانات الذكاء الاصطناعي (تم تفعيل الموديل الحقيقي 🚀) ---
        List<SmartPrediction> aiPredictions = [];
        
        // لو عندنا أدوية في المخزن، هنبعت الـ ID بتاع أحدث دواء عشان الموديل يتوقعه
        if (recentDrugs.isNotEmpty) {
          int firstDrugId = recentDrugs.first.id;
          SmartPrediction? realPrediction = await getAiPrediction(firstDrugId);
          
          if (realPrediction != null) {
            aiPredictions.add(realPrediction);
          }
        }

        // بنجمع كل ده ونرجعه للشاشة في القالب اللي هي فاهماه
        return DashboardData(
          summary: DashboardSummary(
            totalDrugs: total,
            availableDrugs: available,
            lowStockDrugs: lowStock,
            outOfStock: outOfStock,
            predictedShortage: aiPredictions.length,
          ),
          stockPercent: StockPercentage(
            available: availablePercent,
            lowStock: lowStockPercent,
            outOfStock: outOfStockPercent,
          ),
          alerts: alerts,
          recentDrugs: recentDrugs,
          aiPredictions: aiPredictions,
        );
      } else {
        throw Exception('فشل في الاتصال بالسيرفر. الكود: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('تأكد إن سيرفر الباك إند شغال! الخطأ: $e');
    }
  }

  // =================================================================
  // --- الدوال الجديدة لإدارة الأدوية (CRUD Operations) ---
  // =================================================================

  @override
  Future<bool> addMedication(Map<String, dynamic> drugData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add_medication/'), 
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: json.encode(drugData),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('خطأ في إضافة الدواء: $e');
      return false;
    }
  }

  @override
  Future<bool> updateMedication(int id, Map<String, dynamic> drugData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/medications/$id/'), // رابط التعديل (PUT)
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: json.encode(drugData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('خطأ في تعديل الدواء: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteMedication(int id) async {
    try {
      final response = await http.delete(
        // 👇 التعديل التالت: تعديل رابط الحذف عشان يكلم الباك إند صح
        Uri.parse('$baseUrl/delete_medication/$id'), 
      );
      // 204 معناها No Content (تم الحذف بنجاح)
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('خطأ في حذف الدواء: $e');
      return false;
    }
  }

  @override
  Future<SmartPrediction?> getAiPrediction(int medId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/predict/$medId'));
      
      if (response.statusCode == 200) {
        // فك تشفير الرد اللي جاي من بايثون
        var result = json.decode(utf8.decode(response.bodyBytes));
        
        // استخراج البيانات وتجهيزها لكارت الداشبورد
        String probabilityStr = result['shortage_probability'] ?? '0%';
        // تحويل النص '85.5%' لرقم 85.5 عشان الموديل بتاعنا
        double confidence = double.tryParse(probabilityStr.replaceAll('%', '')) ?? 0.0;
        
        return SmartPrediction(
          drugName: result['medication_name'],
          expectedShortageDate: "خلال 7 أيام", // أو تجيبها من السيرفر لو عاملها
          confidenceLevel: confidence,
          recommendation: result['message'] ?? result['status'],
        );
      }
      return null;
    } catch (e) {
      print('خطأ في الاتصال بموديل الذكاء الاصطناعي: $e');
      return null;
    }
  }
  // 👇 دالة البيع الجديدة 👇
  @override
  Future<bool> sellMedication(int id, int quantity) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/sell_medication/$id'),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        // بنبعت الكمية في شكل JSON زي ما بايثون مستنيها بالظبط
        body: json.encode({"quantity": quantity}), 
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('خطأ في عملية البيع: $e');
      return false;
    }
  }
}