import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';

class AiPredictionWidget extends StatelessWidget {
  final SmartPrediction? activePrediction;
  final bool isLoading;

  const AiPredictionWidget({
    super.key,
    required this.activePrediction,
    required this.isLoading,
  });

  String calculateRemainingDays(double confidence) {
    if (confidence >= 80) return "1 - 3 أيام (حرج جداً)";
    if (confidence >= 50) return "4 - 7 أيام (تحذير)";
    if (confidence >= 30) return "8 - 14 يوم (مستقر نسبياً)";
    return "أكثر من أسبوعين (آمن)";
  }

  @override
  Widget build(BuildContext context) {
    if (activePrediction == null && !isLoading) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurpleAccent, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.yellowAccent),
              SizedBox(width: 8),
              Text('توقعات الذكاء الاصطناعي ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (activePrediction != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('دواء: ${activePrediction!.drugName}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                  child: Text('نسبة الخطر: ${activePrediction!.confidenceLevel}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                
                Text('المخزون يكفي لمدة: ${calculateRemainingDays(activePrediction!.confidenceLevel)}', style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30, width: 1)
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.yellowAccent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      activePrediction!.recommendation, 
                      style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 14, fontWeight: FontWeight.w500)
                    )
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}