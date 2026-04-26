import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  double totalSales = 0;
  int txCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyReport();
  }

  /// Extremely fast direct SQLite read targeting index
  Future<void> _loadDailyReport() async {
    final db = await DatabaseHelper.instance.database;
    final today = DateTime.now().toIso8601String().substring(0, 10); // Matches 'YYYY-MM-DD' pattern

    final result = await db.rawQuery('''
      SELECT COUNT(id) as count, SUM(total_amount) as sum 
      FROM sales 
      WHERE created_at LIKE '$today%'
    ''');

    setState(() {
      txCount = result.first['count'] as int? ?? 0;
      totalSales = result.first['sum'] as double? ?? 0.0;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقارير اليوم')),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildStatCard('إجمالي الدخل اليوم', '$totalSales دينار', Icons.monetization_on, Colors.blue),
                const SizedBox(height: 16),
                _buildStatCard('عدد المبيعات', '$txCount عملية', Icons.receipt, Colors.orange),
              ],
            ),
          )
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 48, color: color),
        title: Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)),
        subtitle: Text(value, style: TextStyle(fontSize: 28, color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
