import 'package:flutter/material.dart';
import 'package:mohassib/core/database/database_helper.dart';
import '../models/sales_models.dart';
import 'package:intl/intl.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});
  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<SaleModel> _sales = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    final data = await DatabaseHelper.instance.getSalesHistory();
    setState(() {
      _sales = data.map((m) => SaleModel.fromMap(m as Map<String, dynamic>)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      appBar: AppBar(
        title: const Text('سجل ', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
        : _sales.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sales.length,
              itemBuilder: (ctx, i) {
                final sale = _sales[i];
                return _saleCard(sale);
              },
            ),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.history, color: Colors.white10, size: 80),
    const SizedBox(height: 16),
    const Text('لا توجد مبيعات مسجلة بعد', style: TextStyle(color: Colors.white38, fontSize: 16)),
  ]));

  Widget _saleCard(SaleModel sale) {
    final date = DateTime.parse(sale.createdAt);
    final timeStr = DateFormat('hh:mm a').format(date);
    final dateStr = DateFormat('yyyy/MM/dd').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(children: [
          Text('#${sale.saleNumber}', style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${sale.totalAmount.toStringAsFixed(2)} ر.ي', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            Icon(SaleModel.methodIcon(sale.paymentMethod), size: 14, color: Colors.white38),
            const SizedBox(width: 4),
            Text(SaleModel.methodLabel(sale.paymentMethod), style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const Spacer(),
            Text('$dateStr | $timeStr', style: const TextStyle(color: Colors.white24, fontSize: 11)),
          ]),
        ),
        onTap: () => _showSaleDetails(sale),
      ),
    );
  }

  void _showSaleDetails(SaleModel sale) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('تفاصيل الفاتورة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const Divider(color: Colors.white10, height: 30),
          ...sale.items.map((it) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Text('${it.total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white)),
              const Spacer(),
              Text('x${it.quantity}', style: const TextStyle(color: Colors.white38)),
              const SizedBox(width: 8),
              Text(it.productName, style: const TextStyle(color: Colors.white70)),
            ]),
          )).toList(),
          const Divider(color: Colors.white10, height: 30),
          Row(children: [
            Text('${sale.totalAmount.toStringAsFixed(2)} ر.ي', style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 20)),
            const Spacer(),
            const Text('الإجمالي النهائي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 30),
          Row(children: [
            Expanded(child: _actionBtn('طباعة', Icons.print, Colors.blueAccent, () {})),
            const SizedBox(width: 10),
            Expanded(child: _actionBtn('إغلاق', Icons.close, Colors.grey, () => Navigator.pop(ctx))),
          ]),
        ]),
      ),
    );
  }

  Widget _actionBtn(String t, IconData icon, Color color, VoidCallback op) => ElevatedButton.icon(
    onPressed: op,
    icon: Icon(icon, size: 18),
    label: Text(t),
    style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
  );
}
