import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// ملف الرسم البياني الخطي (هنربطه بالداتابيز لاحقاً)
class LineChartWidget extends StatelessWidget {
  const LineChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('معدل سحب دواء (Panadol) آخر 6 أشهر 📉', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Colors.grey, fontSize: 12);
                        Widget text;
                        switch (value.toInt()) {
                          case 1: text = const Text('يناير', style: style); break;
                          case 2: text = const Text('فبراير', style: style); break;
                          case 3: text = const Text('مارس', style: style); break;
                          case 4: text = const Text('أبريل', style: style); break;
                          case 5: text = const Text('مايو', style: style); break;
                          case 6: text = const Text('يونيو', style: style); break;
                          default: text = const Text('', style: style); break;
                        }
                        return Padding(padding: const EdgeInsets.only(top: 8.0), child: text);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 1, maxX: 6, minY: 0, maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(1, 90), FlSpot(2, 75), FlSpot(3, 60), FlSpot(4, 30), FlSpot(5, 15), FlSpot(6, 0)],
                    isCurved: true, color: Colors.redAccent, barWidth: 4, isStrokeCapRound: true, dotData: const FlDotData(show: true), belowBarData: BarAreaData(show: true, color: Colors.redAccent.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}