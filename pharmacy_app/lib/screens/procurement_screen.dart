import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProcurementScreen extends StatefulWidget {
  @override
  _ProcurementScreenState createState() => _ProcurementScreenState();
}

class _ProcurementScreenState extends State<ProcurementScreen> {
  List<dynamic> items = [];
  bool isLoading = true;

  final String baseUrl = "http://127.0.0.1:8000";

  @override
  void initState() {
    super.initState();
    fetchSuggestions();
  }

  Future<void> fetchSuggestions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/procurement/suggestions'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          // بنعمل نسخة من الكمية المقترحة عشان نخلي الصيدلي يقدر يعدل عليها
          items = data.map((item) {
            item['requested_quantity'] = item['suggested_quantity'];
            return item;
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching suggestions: $e");
      setState(() { isLoading = false; });
    }
  }

  Future<void> confirmOrder() async {
    final orderData = {
      "items": items.map((item) => {
        "product_id": item['product_id'],
        "requested_quantity": item['requested_quantity'],
        "total_cost": item['requested_quantity'] * item['unit_price'],
        "urgency_tag": item['urgency_tag']
      }).toList()
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/procurement/confirm'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(orderData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم إرسال الطلبية بنجاح!'), backgroundColor: Colors.green),
        );
        setState(() { items.clear(); }); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ حصل خطأ في الاتصال بالخادم'), backgroundColor: Colors.red),
      );
    }
  }

  double get totalOrderCost {
    return items.fold(0, (sum, item) => sum + (item['requested_quantity'] * item['unit_price']));
  }

  Color getUrgencyColor(String tag) {
    if (tag == "Critical") return Colors.red;
    if (tag == "High") return Colors.orange;
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الطلبيات الذكية'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(child: Text(' المخزون آمن.. لا توجد نواقص تحتاج لطلبيات', style: TextStyle(fontSize: 18)))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      elevation: 3,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item['brand_name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Chip(
                                  label: Text(item['urgency_tag'], style: TextStyle(color: Colors.white, fontSize: 12)),
                                  backgroundColor: getUrgencyColor(item['urgency_tag']),
                                )
                              ],
                            ),
                            SizedBox(height: 8),
                            Text('اقتراح الذكاء الاصطناعي: ${item['suggested_quantity']} علبة', 
                              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600)),
                            Text('المخزون الفعلي: ${item['current_stock']} | سعر الوحدة: ${item['unit_price']} ج.م',
                              style: TextStyle(color: Colors.grey[700])),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('الكمية المطلوبة:', style: TextStyle(fontSize: 16)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                                      onPressed: () {
                                        if (item['requested_quantity'] > 1) {
                                          setState(() { item['requested_quantity']--; });
                                        }
                                      },
                                    ),
                                    Text('${item['requested_quantity']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: Icon(Icons.add_circle_outline, color: Colors.green),
                                      onPressed: () {
                                        setState(() { item['requested_quantity']++; });
                                      },
                                    ),
                                  ],
                                )
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('تكلفة الصنف: ${(item['requested_quantity'] * item['unit_price']).toStringAsFixed(2)} ج.م', 
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() { items.removeAt(index); });
                                  },
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: items.isEmpty ? null : Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
        ),
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('إجمالي التكلفة:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('${totalOrderCost.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: confirmOrder,
              icon: Icon(Icons.check_circle),
              label: Text('تأكيد الطلبية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}