import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'services/api_dashboard_service.dart'; // ده الملف السوبر اللي هنعتمد عليه

void main() {
  runApp(const PharmacyApp());
}

class PharmacyApp extends StatelessWidget {
  const PharmacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نظام الصيدلية',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      // هنا بيحصل الـ Dependency Injection!
      // بنشغل الداشبورد ونبعتلها كلاس البيانات الوهمية
      home: DashboardScreen(dashboardService: ApiDashboardService()),
    );
  }
}