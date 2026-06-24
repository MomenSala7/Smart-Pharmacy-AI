import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';
import '../services/dashboard_service_interface.dart';
import 'add_medication_screen.dart';
import 'procurement_screen.dart'; 
import 'inventory_screen.dart';

import '../widgets/summary_cards_widget.dart';
import '../widgets/ai_prediction_widget.dart';
import '../widgets/line_chart_widget.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/recent_drugs_table_widget.dart';
import '../widgets/alerts_list_widget.dart';

class DashboardScreen extends StatefulWidget {
  final IDashboardService dashboardService;

  const DashboardScreen({super.key, required this.dashboardService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardData> _dashboardDataFuture;
  
  SmartPrediction? _customPrediction; 
  bool _isLoadingPrediction = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _customPrediction = null; 
      _dashboardDataFuture = widget.dashboardService.getDashboardData();
    });
  }

  
  Future<void> _fetchSpecificPrediction(int drugId) async {
    setState(() {
      _isLoadingPrediction = true;
    });

    final prediction = await widget.dashboardService.getAiPrediction(drugId);

    setState(() {
      _isLoadingPrediction = false;
      if (prediction != null) {
        _customPrediction = prediction;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في جلب التوقع، تأكد من السيرفر! ⚠️'), backgroundColor: Colors.red),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم - المخزون 💊', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          
          IconButton(
            icon: const Icon(Icons.shopping_cart_checkout, size: 28),
            tooltip: 'الطلبيات الذكية',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProcurementScreen()),
              );
            },
          ),

          
IconButton(
  icon: const Icon(Icons.inventory_2, size: 28),
  tooltip: 'جرد المخزون',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InventoryScreen()),
    );
  },
),
         
          IconButton(
            icon: const Icon(Icons.add_box, size: 28),
            tooltip: 'إضافة دواء',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddMedicationScreen(service: widget.dashboardService)),
              );
              if (result == true) {
                _loadData(); 
              }
            },
          )
        ],
      ),
      body: FutureBuilder<DashboardData>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          } else if (snapshot.hasError) {
            return Center(child: Text('حصلت مشكلة:\n${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('لا توجد بيانات.'));
          }

          final data = snapshot.data!;
          SmartPrediction? activePrediction = _customPrediction ?? (data.aiPredictions.isNotEmpty ? data.aiPredictions.first : null);

          
          return SingleChildScrollView(
            child: Column(
              children: [
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SummaryCardsWidget(
                    total: data.summary.totalDrugs,
                    available: data.summary.availableDrugs,
                    lowStock: data.summary.lowStockDrugs,
                    outOfStock: data.summary.outOfStock,
                  ),
                ),
                const Divider(thickness: 1, height: 1),
                const SizedBox(height: 10),
                
                
                AiPredictionWidget(
                  activePrediction: activePrediction, 
                  isLoading: _isLoadingPrediction
                ),

                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                
                child: LineChartWidget(drugName: activePrediction?.drugName ?? 'دواء عام'),
                ),
                
                
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: PieChartWidget(stockPercent: data.stockPercent),
                ),

                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: RecentDrugsTableWidget(
                    recentDrugs: data.recentDrugs,
                    dashboardService: widget.dashboardService,
                    onRefresh: _loadData, 
                    onFetchPrediction: _fetchSpecificPrediction, 
                  ),
                ),

                
                AlertsListWidget(alerts: data.alerts),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}