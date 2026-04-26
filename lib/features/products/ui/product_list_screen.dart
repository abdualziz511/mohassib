import 'package:flutter/material.dart';
import 'package:mohassib/features/products/models/product_model.dart';
import 'package:provider/provider.dart';
import '../provider/product_provider.dart';
import 'add_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final filteredProducts = provider.products.where((p) {
      final name = p.name.toLowerCase();
      final barcode = (p.barcode ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || barcode.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      appBar: AppBar(
        title: const Text('إدارة المنتجات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(children: [
        // ── شريط البحث
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'بحث باسم المنتج أو الباركود...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.cyan),
              filled: true,
              fillColor: const Color(0xFF1A1A24),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),

        // ── القائمة
        Expanded(
          child: provider.isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
            : filteredProducts.isEmpty 
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (ctx, i) {
                    final p = filteredProducts[i];
                    return _productCard(context, p, provider);
                  },
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.cyan,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة منتج جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _openSheet(context, provider),
      ),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.inventory_2_outlined, color: Colors.white10, size: 80),
    const SizedBox(height: 16),
    Text(_searchQuery.isEmpty ? 'لا توجد منتجات بعد' : 'لم يتم العثور على نتائج', style: const TextStyle(color: Colors.white38, fontSize: 16)),
  ]));

  Widget _productCard(BuildContext context, ProductModel p, ProductProvider provider) {
    final statusColor = p.isOutOfStock ? Colors.red : (p.isLowStock ? Colors.orange : Colors.green);
    final statusText = p.isOutOfStock ? 'نافد' : (p.isLowStock ? 'منخفض' : 'متوفر');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => _openSheet(context, provider, existing: p),
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: const Color(0xFF22222E), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.inventory_2, color: statusColor.withOpacity(0.5), size: 24),
        ),
        title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          Text('${p.sellPrice.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Text('المخزون: ${p.quantity} ${p.unit}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ]),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white30),
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('تعديل')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('حذف', style: TextStyle(color: Colors.red))])),
          ],
          onSelected: (v) {
            if (v == 'edit') _openSheet(context, provider, existing: p);
            if (v == 'delete') _confirmDelete(context, p, provider);
          },
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, ProductProvider p, {dynamic existing}) {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: p,
        child: AddEditProductSheet(existing: existing),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductModel p, ProductProvider provider) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A24),
      title: const Text('حذف المنتج؟', textAlign: TextAlign.right, style: TextStyle(color: Colors.white)),
      content: Text('هل أنت متأكد من حذف "${p.name}"؟ لا يمكن التراجع عن هذا الإجراء.', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        TextButton(onPressed: () { provider.deleteProduct(p.id!); Navigator.pop(ctx); }, child: const Text('حذف', style: TextStyle(color: Colors.red))),
      ],
    ));
  }
}
