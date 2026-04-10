import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';

// قائمة التنبيهات السفلية هنا 
class AlertsListWidget extends StatelessWidget {
  final List<DrugAlert> alerts;

  const AlertsListWidget({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('حالة الأدوية والتنبيهات 🚨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: alerts.length, 
          itemBuilder: (context, index) {
            final alert = alerts[index];
            bool isCritical = alert.alertType == 'out_of_stock';
            bool isWarning = alert.alertType == 'low_stock';
            
            Color statusColor = isCritical ? Colors.red : (isWarning ? Colors.orange : Colors.blue);
            IconData statusIcon = isCritical ? Icons.cancel : (isWarning ? Icons.warning_amber_rounded : Icons.info_outline);

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(statusIcon, color: statusColor, size: 30),
                ),
                title: Text(alert.drugName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(alert.message, style: const TextStyle(height: 1.5, fontSize: 14)),
                ),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('الحالة', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      isCritical ? 'نفد' : (isWarning ? 'قليل' : 'توقع'),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}