import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/dashboard_models.dart';

// ملف الرسم الدائري (Donut Chart) لنسب المخزون
class PieChartWidget extends StatelessWidget {
  final StockPercentage stockPercent;

  const PieChartWidget({super.key, required this.stockPercent});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(value: stockPercent.available, color: Colors.green, title: '${stockPercent.available.toInt()}%', radius: 25, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      PieChartSectionData(value: stockPercent.lowStock, color: Colors.orange, title: '${stockPercent.lowStock.toInt()}%', radius: 30, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      PieChartSectionData(value: stockPercent.outOfStock, color: Colors.red, title: '${stockPercent.outOfStock.toInt()}%', radius: 35, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
                const Column(mainAxisSize: MainAxisSize.min, children: [Text('المخزون', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold))])
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem('متاح', Colors.green), const SizedBox(height: 8),
                _buildLegendItem('قليل', Colors.orange), const SizedBox(height: 8),
                _buildLegendItem('نفد', Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}