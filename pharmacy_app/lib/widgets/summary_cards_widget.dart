import 'package:flutter/material.dart';

class SummaryCardsWidget extends StatelessWidget {
  final int total;
  final int available;
  final int lowStock;
  final int outOfStock;

  const SummaryCardsWidget({
    super.key,
    required this.total,
    required this.available,
    required this.lowStock,
    required this.outOfStock,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.0, 
      runSpacing: 12.0, 
      alignment: WrapAlignment.center, 
      children: [
        _buildSummaryCard('إجمالي', total, Colors.blue),
        _buildSummaryCard('متاح', available, Colors.green),
        _buildSummaryCard('قليل', lowStock, Colors.orange),
        _buildSummaryCard('نواقص', outOfStock, Colors.red),
      ],
    );
  }

  Widget _buildSummaryCard(String title, int value, Color color) {
    return Container(
      width: 100, 
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1), 
            blurRadius: 10, 
            spreadRadius: 2, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}