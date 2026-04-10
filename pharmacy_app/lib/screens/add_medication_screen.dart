import 'package:flutter/material.dart';
import '../services/dashboard_service_interface.dart';

class AddMedicationScreen extends StatefulWidget {
  final IDashboardService service;
  
  const AddMedicationScreen({super.key, required this.service});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _companyController = TextEditingController();

  bool _isLoading = false; // عشان نظهر علامة تحميل وإحنا بنبعت للسيرفر

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // تجهيز البيانات زي ما الباك إند متوقعها
      // تجهيز البيانات زي ما الباك إند (main.py) متوقعها بالظبط!
      final newData = {
        "name": _nameController.text,
        "category": _companyController.text, // بعتنا الشركة كأنها التصنيف مؤقتاً
        "current_stock": int.parse(_stockController.text),
        "price": 50.0,            // قيمة افتراضية
        "min_stock": 10,          // قيمة افتراضية
        "daily_usage": 5.0,       // قيمة افتراضية عشان موديل الـ ML
        "lead_time_days": 3       // قيمة افتراضية عشان موديل الـ ML
      };

      // إرسال البيانات للسيرفر
      bool success = await widget.service.addMedication(newData);
      
      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الدواء بنجاح! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // بنقفل الشاشة ونرجع true عشان الداشبورد تعرف إن في داتا اتضافت
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حصلت مشكلة أثناء الإضافة، راجع السيرفر! ⚠️'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة دواء جديد ➕', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('بيانات الدواء الأساسية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 20),
              
              // خانة اسم الدواء
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'اسم الدواء',
                  prefixIcon: const Icon(Icons.medical_services, color: Colors.teal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value!.isEmpty ? 'برجاء إدخال اسم الدواء' : null,
              ),
              const SizedBox(height: 15),
              
              // خانة الشركة
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: 'الشركة المصنعة',
                  prefixIcon: const Icon(Icons.business, color: Colors.teal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value!.isEmpty ? 'برجاء إدخال اسم الشركة' : null,
              ),
              const SizedBox(height: 15),

              // خانة الكمية
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'الكمية المتاحة في المخزن',
                  prefixIcon: const Icon(Icons.inventory, color: Colors.teal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value!.isEmpty ? 'برجاء إدخال الكمية' : null,
              ),
              const SizedBox(height: 40),
              
              // زرار بتع الحفظ
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('حفظ في قاعدة البيانات', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}