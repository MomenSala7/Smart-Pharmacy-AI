import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // بما إننا هنشغل التطبيق على نفس الجهاز (كروم أو ويندوز)، هنستخدم 127.0.0.1
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<List<dynamic>> getMedications() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/medications/'));
      
      if (response.statusCode == 200) {
        // بنعمل فك للبيانات، واستخدمنا utf8 عشان لو في داتا بالعربي تظهر صح
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('فشل في جلب البيانات من السيرفر. كود الخطأ: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('تأكد إن سيرفر الباك إند شغال يا هندسة! الخطأ: $e');
    }
  }
}