import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<dynamic> allMedications = [];
  List<dynamic> filteredMedications = [];
  bool isLoading = true;

  final String baseUrl = "http://127.0.0.1:8000";
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchInventory();
    // مراقبة شريط البحث عشان يفلتر الداتا مع كل حرف بيتكتب
    searchController.addListener(() {
      filterSearchResults(searchController.text);
    });
  }

  Future<void> fetchInventory() async {
    setState(() { isLoading = true; });
    try {
      final response = await http.get(Uri.parse('$baseUrl/medications/'));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          allMedications = data;
          filteredMedications = data;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching inventory: $e");
      setState(() { isLoading = false; });
    }
  }

  // 🔍 دالة الفلترة (البحث)
  void filterSearchResults(String query) {
    if (query.isEmpty) {
      setState(() { filteredMedications = allMedications; });
      return;
    }
    setState(() {
      filteredMedications = allMedications.where((med) =>
          med['name'].toString().toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  // 🛒 دالة البيع
  Future<void> sellMedication(int id, int quantity) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/sell_medication/$id'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"quantity": quantity}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم البيع بنجاح وتسجيل الشحنة'), backgroundColor: Colors.green));
        fetchInventory(); // تحديث القائمة بعد البيع
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ الكمية لا تكفي أو حدث خطأ'), backgroundColor: Colors.red));
      }
    } catch (e) {
      print(e);
    }
  }

  // 🗑️ دالة الحذف
  Future<void> deleteMedication(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/delete_medication/$id'));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ تم الحذف بنجاح من الداتابيز'), backgroundColor: Colors.green));
        fetchInventory(); // تحديث القائمة
      }
    } catch (e) {
      print(e);
    }
  }

  // 🤖 دالة توقع الذكاء الاصطناعي السريع
  Future<void> predictShortage(int id, String name) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.teal)),
    );
    try {
      final response = await http.get(Uri.parse('$baseUrl/predict/$id'));
      Navigator.pop(context); // قفل اللودينج
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('توقع الذكاء الاصطناعي \n$name', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('نسبة الخطر: ${data['shortage_probability']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 10),
                Text(data['message'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  // --- النوافذ المنبثقة للتأكيد ---

  void showSellDialog(int id, String name, int maxQuantity) {
    if (maxQuantity == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ المخزون صفر! لا يمكن البيع'), backgroundColor: Colors.orange));
      return;
    }
    int quantityToSell = 1;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: Text('بيع دواء: $name'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('حدد الكمية المراد بيعها للخروج من المخزن:'),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () {
                        if (quantityToSell > 1) setStateSB(() => quantityToSell--);
                      }),
                      Text('$quantityToSell', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), onPressed: () {
                        if (quantityToSell < maxQuantity) setStateSB(() => quantityToSell++);
                      }),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    sellMedication(id, quantityToSell);
                  },
                  child: const Text('تأكيد البيع'),
                )
              ],
            );
          }
        );
      }
    );
  }

  void showDeleteDialog(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف ⚠️', style: TextStyle(color: Colors.red)),
        content: Text('هل أنت متأكد من حذف ($name) من المخزون نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              deleteMedication(id);
            },
            child: const Text('حذف'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 جرد وإدارة المخزون', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 🌟 شريط البحث
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'ابحث عن دواء بالاسم...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                suffixIcon: searchController.text.isNotEmpty 
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { searchController.clear(); }) 
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.teal, width: 2), borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300, width: 1), borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : filteredMedications.isEmpty
                    ? const Center(child: Text('لا توجد أدوية مطابقة لبحثك', style: TextStyle(fontSize: 18)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredMedications.length,
                        itemBuilder: (context, index) {
                          final med = filteredMedications[index];
                          final bool isLowStock = med['current_stock'] <= med['min_stock'];

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isLowStock ? Colors.red.shade100 : Colors.teal.shade100,
                                        child: Icon(Icons.medication, color: isLowStock ? Colors.red : Colors.teal),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(med['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                            Text('القسم: ${med['category']} | السعر: ${med['price']} ج.م', style: TextStyle(color: Colors.grey[700])),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          const Text('المخزون', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          Text(
                                            '${med['current_stock']}',
                                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isLowStock ? Colors.red : Colors.green),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  // 🌟 أزرار العمليات (بيع - توقع - حذف)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => showSellDialog(med['id'], med['name'], med['current_stock']),
                                        icon: const Icon(Icons.point_of_sale, color: Colors.green),
                                        label: const Text('بيع', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => predictShortage(med['id'], med['name']),
                                        icon: const Icon(Icons.auto_awesome, color: Colors.deepPurple),
                                        label: const Text('توقع AI', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => showDeleteDialog(med['id'], med['name']),
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        label: const Text('حذف', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}