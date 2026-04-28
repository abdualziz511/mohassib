import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../provider/product_provider.dart';
import 'add_product_screen.dart';

class LowStockScreen extends StatelessWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final lowStock = pp.lowStockProducts;
    final outOfStock = pp.products.where((p) => p.isOutOfStock).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text('تنبيهات المخزون', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: pp.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : (lowStock.isEmpty && outOfStock.isEmpty)
              ? _emptyState()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (outOfStock.isNotEmpty) ...[
                      _sectionHeader('نفذ المخزون', Icons.remove_shopping_cart, Colors.redAccent, outOfStock.length),
                      const SizedBox(height: 8),
                      ...outOfStock.map((p) => _productCard(context, p, Colors.redAccent, pp)),
                      const SizedBox(height: 24),
                    ],
                    if (lowStock.isNotEmpty) ...[
                      _sectionHeader('مخزون منخفض', Icons.warning_amber_rounded, Colors.orangeAccent, lowStock.length),
                      const SizedBox(height: 8),
                      ...lowStock.map((p) => _productCard(context, p, Colors.orangeAccent, pp)),
                    ],
                  ],
                ),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 80),
    const SizedBox(height: 16),
    const Text('المخزون بخير!', style: TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('لا توجد منتجات تحتاج إلى تجديد المخزون', style: TextStyle(color: Colors.grey, fontSize: 14)),
  ]));

  Widget _sectionHeader(String title, IconData icon, Color color, int count) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: Text('$count منتج', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(width: 8),
      Icon(icon, color: color, size: 20),
    ],
  );

  Widget _productCard(BuildContext context, ProductModel p, Color accentColor, ProductProvider pp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(children: [
        // زر تعديل السريع
        InkWell(
          onTap: () => _openEdit(context, p, pp),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 18),
          ),
        ),
        const SizedBox(width: 14),

        // المعلومات
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(p.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text(p.category, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(width: 8),
            Text('سعر البيع: ${p.sellPrice.toStringAsFixed(0)} ر.ي',
                style: const TextStyle(color: Colors.cyan, fontSize: 11)),
          ]),
        ])),
        const SizedBox(width: 14),

        // الكمية
        Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${p.quantity} ${p.unit}',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(height: 4),
          Text('حد التنبيه: ${p.lowStockAlert.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white24, fontSize: 10)),
        ]),
      ]),
    );
  }

  void _openEdit(BuildContext context, ProductModel p, ProductProvider pp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: pp,
        child: AddEditProductSheet(existing: p),
      ),
    );
  }
}
