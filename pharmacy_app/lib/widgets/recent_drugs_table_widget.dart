import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';
import '../services/dashboard_service_interface.dart';

// (الكاشير، الـ AI، الحذف) هنا
// بنستقبل الـ service عشان نكلم السيرفر، وبنستقبل onRefresh عشان نحدث الشاشة الأم
class RecentDrugsTableWidget extends StatelessWidget {
  final List<RecentDrug> recentDrugs;
  final IDashboardService dashboardService;
  final VoidCallback onRefresh; // عشان نأمر الشاشة الرئيسية تعمل ريفريش
  final Function(int) onFetchPrediction; // عشان نأمر الشاشة الرئيسية تجيب التوقع

  const RecentDrugsTableWidget({
    super.key,
    required this.recentDrugs,
    required this.dashboardService,
    required this.onRefresh,
    required this.onFetchPrediction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('آخر التحديثات 📝', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.resolveWith((states) => Colors.teal.shade50),
              horizontalMargin: 12,
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('الدواء', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الشركة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('تاريخ التحديث', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold))), 
              ],
              rows: recentDrugs.map((drug) {
                bool isAvailable = drug.status == 'Available';
                bool isLow = drug.status == 'Low Stock';
                
                Color statusColor = isAvailable ? Colors.green : (isLow ? Colors.orange : Colors.red);
                String statusText = isAvailable ? 'متاح' : (isLow ? 'قليل' : 'نفد');

                return DataRow(cells: [
                  DataCell(Text(drug.drugName, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(drug.companyName)),
                  DataCell(
                    Center( 
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withOpacity(0.5), width: 1), 
                        ),
                        child: FittedBox( 
                          fit: BoxFit.scaleDown,
                          child: Text(
                            statusText, 
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(drug.dateUpdated, style: const TextStyle(color: Colors.grey))),
                  
                  // هنا خلينا الخلية تشيل 3 أزرار جنب بعض
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        
                        // زرار الكاشير (البيع)
                        IconButton(
                          icon: const Icon(Icons.point_of_sale, color: Colors.green), 
                          tooltip: 'تسجيل بيع',
                          onPressed: () async {
                            int quantityToSell = 1; 
                            
                            bool? confirmSale = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                int tempQuantity = 1; 
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Row(
                                        children: [
                                          const Icon(Icons.shopping_cart_checkout, color: Colors.green),
                                          const SizedBox(width: 8),
                                          Text('بيع: ${drug.drugName}', style: const TextStyle(color: Colors.green, fontSize: 18)),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('حدد الكمية التي تم بيعها للعميل:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 30),
                                                onPressed: () {
                                                  if (tempQuantity > 1) setState(() => tempQuantity--);
                                                },
                                              ),
                                              const SizedBox(width: 15),
                                              Text('$tempQuantity', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                              const SizedBox(width: 15),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 30),
                                                onPressed: () => setState(() => tempQuantity++),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false), 
                                          child: const Text('إلغاء', style: TextStyle(color: Colors.grey))
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                          onPressed: () {
                                            quantityToSell = tempQuantity; 
                                            Navigator.pop(context, true);  
                                          },
                                          child: const Text('تأكيد البيع 💸', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    );
                                  }
                                );
                              },
                            );

                            if (confirmSale == true) {
                              bool success = await dashboardService.sellMedication(drug.id, quantityToSell);
                              
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم بيع $quantityToSell علبة من (${drug.drugName}) بنجاح! 🛒', style: const TextStyle(fontWeight: FontWeight.bold)), 
                                    backgroundColor: Colors.green
                                  )
                                );
                                // بنعمل ريفريش أوتوماتيك للداشبورد 
                                onRefresh();
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('فشل البيع! تأكد إن الكمية المطلوبة متوفرة في المخزن ⚠️'), backgroundColor: Colors.red)
                                );
                              }
                            }
                          },
                        ),

                        // زرار الذكاء الاصطناعي (زي ما هو)
                        IconButton(
                          icon: const Icon(Icons.psychology, color: Colors.deepPurpleAccent), 
                          tooltip: 'تحليل الذكاء الاصطناعي',
                          // بننادي الدالة اللي بتجيب التوقع من الشاشة الرئيسية
                          onPressed: () => onFetchPrediction(drug.id),
                        ),
                        
                        // زرار الحذف (زي ما هو)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'حذف الدواء',
                          onPressed: () async {
                            bool confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('تأكيد الحذف ⚠️', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                                content: Text('هل أنت متأكد إنك عاوز تحذف دواء (${drug.drugName}) نهائياً من قاعدة البيانات؟'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false), 
                                    child: const Text('إلغاء', style: TextStyle(color: Colors.grey))
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => Navigator.pop(context, true), 
                                    child: const Text('نعم، احذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                  ),
                                ],
                              ),
                            ) ?? false;

                            if (confirm) {
                              bool success = await dashboardService.deleteMedication(drug.id);
                              
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم حذف الدواء بنجاح 🗑️', style: TextStyle(fontWeight: FontWeight.bold)), 
                                    backgroundColor: Colors.redAccent
                                  )
                                );
                                onRefresh(); 
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('فشل الحذف، تأكد من اتصال السيرفر ⚠️'))
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}