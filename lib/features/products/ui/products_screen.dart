import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../provider/product_provider.dart';
import 'add_product_screen.dart';
import 'low_stock_screen.dart';
import 'print_barcode_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _selectedCategory = 'الكل';

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // استخراج التصنيفات الفريدة
    final categories = ['الكل', ...{...pp.products.map((p) => p.category)}];

    // تطبيق فلتر التصنيف + البحث
    final displayList = _selectedCategory == 'الكل'
        ? pp.products
        : pp.products.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111116) : const Color(0xFFF5F7FB),
      body: SafeArea(child: Column(children: [
        _appBar(context, pp, isDark),
        _searchBar(context, pp, isDark),
        _categoryBar(categories, isDark),
        _statsRow(pp, isDark),
        pp.isLoading
          ? const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.cyan)))
          : displayList.isEmpty
            ? _empty(isDark)
            : _grid(context, pp, isDark, displayList),
      ])),
    );
  }

  Widget _appBar(BuildContext ctx, ProductProvider pp, bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: [
      _circleBtn(Icons.add, color: Colors.cyan, onTap: () => _openAdd(ctx)),
      const SizedBox(width: 8),
      _circleBtn(Icons.bar_chart, onTap: () => _showReport(ctx, pp, isDark)),
      const SizedBox(width: 8),
      _circleBtn(Icons.qr_code, color: Colors.amberAccent, onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const PrintBarcodeScreen()))),
      const SizedBox(width: 8),
      // زر المخزون المنخفض مع بادج
      Stack(
        clipBehavior: Clip.none,
        children: [
          _circleBtn(Icons.warning_amber_rounded, color: Colors.orangeAccent,
              onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) =>
                ChangeNotifierProvider.value(value: pp, child: const LowStockScreen())))),
          if (pp.lowStockProducts.isNotEmpty)
            Positioned(top: -4, right: -4, child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
              child: Text('${pp.lowStockProducts.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            )),
        ],
      ),
      const Spacer(),
      const Text('المخزون', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      const Spacer(),
      _circleBtn(Icons.tune, onTap: () => _showFilter(ctx, pp, isDark)),
    ]),
  );

  Widget _searchBar(BuildContext ctx, ProductProvider pp, bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: TextField(
      textAlign: TextAlign.right,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      onChanged: (q) => pp.searchProducts(q),
      decoration: InputDecoration(
        hintText: 'بحث عن منتج أو باركود...',
        hintStyle: const TextStyle(color: Colors.grey),
        suffixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A24) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
  );

  Widget _categoryBar(List<String> categories, bool isDark) => SizedBox(
    height: 42,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final cat = categories[i];
        final isActive = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.cyan : (isDark ? const Color(0xFF1A1A24) : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isActive ? Colors.cyan : Colors.white24),
            ),
            child: Text(cat, style: TextStyle(
                color: isActive ? Colors.black : (isDark ? Colors.white70 : Colors.black54),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 12)),
          ),
        );
      },
    ),
  );

  Widget _statsRow(ProductProvider pp, bool isDark) {
    final c = isDark ? const Color(0xFF1A1A24) : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        _statChip('شراء: ${pp.totalBuyValue.toStringAsFixed(0)} ر.ي', Colors.red.shade700, c),
        const SizedBox(width: 8),
        _statChip('بيع: ${pp.totalSellValue.toStringAsFixed(0)} ر.ي', Colors.cyan.shade700, c),
        const SizedBox(width: 8),
        _statChip('ربح: ${pp.expectedProfit.toStringAsFixed(0)} ر.ي', Colors.amber.shade600, c, textColor: Colors.black),
      ]),
    );
  }

  Widget _statChip(String text, Color bg, Color card, {Color textColor = Colors.white}) =>
    Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Center(child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11))),
    ));

  Widget _empty(bool isDark) => Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.inventory_2_outlined, size: 80, color: isDark ? Colors.white24 : Colors.black26),
    const SizedBox(height: 16),
    Text('لا توجد منتجات بعد', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 16)),
    const SizedBox(height: 8),
    Text('اضغط + لإضافة منتجك الأول', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 13)),
  ])));

  Widget _grid(BuildContext context, ProductProvider pp, bool isDark, List<ProductModel> list) => Expanded(
    child: GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.82),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final ProductModel p = list[i];
        return _card(ctx, p, pp, isDark);
      },
    ),
  );

  Widget _card(BuildContext ctx, ProductModel p, ProductProvider pp, bool isDark) {
    final stockColor = pp.stockColor(p);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Stack(children: [
        Column(children: [
          Expanded(flex: 3, child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF22222E) : const Color(0xFFF0F4FF),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: p.imagePath != null
              ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.asset(p.imagePath!, fit: BoxFit.cover))
              : const Center(child: Icon(Icons.inventory_2, color: Colors.white54, size: 40)),
          )),
          Expanded(flex: 2, child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(p.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${p.profit.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
                Text('${p.sellPrice.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
            ]),
          )),
        ]),
        // كمية المخزون
        Positioned(top: 8, right: 8, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: stockColor, borderRadius: BorderRadius.circular(10)),
          child: Text('${p.quantity} ${p.unit}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        )),
        // حذف
        Positioned(top: 6, left: 6, child: InkWell(
          onTap: () => _confirmDelete(ctx, p, pp),
          child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFF1A1A24), shape: BoxShape.circle),
            child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16)),
        )),
        // تعديل (tap anywhere)
        Positioned.fill(child: Material(color: Colors.transparent, child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openEdit(ctx, p),
        ))),
      ]),
    );
  }

  Widget _circleBtn(IconData icon, {Color? color, VoidCallback? onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFF1A1A24), shape: BoxShape.circle),
      child: Icon(icon, color: color ?? Colors.white70, size: 20)),
  );

  void _openAdd(BuildContext ctx) => showModalBottomSheet(
    context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(value: ctx.read<ProductProvider>(), child: const AddEditProductSheet()));

  void _openEdit(BuildContext ctx, ProductModel p) => showModalBottomSheet(
    context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(value: ctx.read<ProductProvider>(), child: AddEditProductSheet(existing: p)));

  void _confirmDelete(BuildContext ctx, ProductModel p, ProductProvider pp) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E2A),
      title: const Text('حذف المنتج', style: TextStyle(color: Colors.white), textDirection: TextDirection.rtl),
      content: Text('هل تريد حذف "${p.name}"؟', style: const TextStyle(color: Colors.grey), textDirection: TextDirection.rtl),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        TextButton(onPressed: () { pp.deleteProduct(p.id!); Navigator.pop(ctx); }, child: const Text('حذف', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
      ],
    ),
  );

  void _showReport(BuildContext ctx, ProductProvider pp, bool isDark) => showModalBottomSheet(
    context: ctx, isScrollControlled: true, backgroundColor: const Color(0xFF1A1A24),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _StockReportSheet(pp: pp));

  void _showFilter(BuildContext ctx, ProductProvider pp, bool isDark) => Navigator.push(
    ctx,
    MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
      value: pp, child: const LowStockScreen())),
  );
}

// ── تقرير المخزون ─────────────────────────────────────────────
class _StockReportSheet extends StatelessWidget {
  final ProductProvider pp;
  const _StockReportSheet({required this.pp});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const Spacer(),
          const Text('تقرير المخزون', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        Container(color: const Color(0xFF162529), padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: const Row(children: [
            Expanded(child: Center(child: Text('ربح', style: TextStyle(color: Colors.greenAccent, fontSize: 11)))),
            Expanded(child: Center(child: Text('بيع', style: TextStyle(color: Colors.cyan, fontSize: 11)))),
            Expanded(child: Center(child: Text('شراء', style: TextStyle(color: Colors.red, fontSize: 11)))),
            Expanded(child: Center(child: Text('كمية', style: TextStyle(color: Colors.amber, fontSize: 11)))),
            Expanded(flex: 2, child: Center(child: Text('المنتج', style: TextStyle(color: Colors.white, fontSize: 11)))),
          ])),
        Expanded(child: ListView.builder(
          itemCount: pp.products.length,
          itemBuilder: (_, i) {
            final ProductModel p = pp.products[i];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
              child: Row(children: [
                Expanded(child: Center(child: Text(p.profit.toStringAsFixed(0), style: const TextStyle(color: Colors.greenAccent, fontSize: 12)))),
                Expanded(child: Center(child: Text(p.sellPrice.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 12)))),
                Expanded(child: Center(child: Text(p.buyPrice.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 12)))),
                Expanded(child: Center(child: Text('${p.quantity} ${p.unit}', style: const TextStyle(color: Colors.white, fontSize: 12)))),
                Expanded(flex: 2, child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
              ]),
            );
          },
        )),
        const Divider(color: Colors.white10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('ربح: ${pp.expectedProfit.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          Text('بيع: ${pp.totalSellValue.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
          Text('شراء: ${pp.totalBuyValue.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ]),
      ])),
    );
  }
}

