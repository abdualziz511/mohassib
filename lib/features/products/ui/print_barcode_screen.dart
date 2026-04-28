import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/product_provider.dart';
import '../models/product_model.dart';
import '../../../core/utils/pdf_service.dart';

class PrintBarcodeScreen extends StatefulWidget {
  const PrintBarcodeScreen({super.key});

  @override
  State<PrintBarcodeScreen> createState() => _PrintBarcodeScreenState();
}

class _PrintBarcodeScreenState extends State<PrintBarcodeScreen> {
  bool _showPrice = true;
  String _searchQuery = '';
  final Map<int, int> _printQuantities = {};
  final Set<int> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // فلترة المنتجات بناءً على البحث
    final filteredProducts = pp.products.where((p) {
      final nameMatch = p.name.contains(_searchQuery);
      final barcodeMatch = p.barcode?.contains(_searchQuery) ?? false;
      return nameMatch || barcodeMatch;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111116) : const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('طباعة ملصقات الباركود', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildSearchAndSettings(isDark),
          Expanded(
            child: filteredProducts.isEmpty 
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (ctx, i) => _buildProductItem(filteredProducts[i], isDark),
                ),
          ),
          _buildBottomAction(isDark),
        ],
      ),
    );
  }

  Widget _buildSearchAndSettings(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(
          textAlign: TextAlign.right,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'بحث باسم المنتج أو الباركود...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Colors.cyan),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1A24) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Switch(
              value: _showPrice,
              onChanged: (v) => setState(() => _showPrice = v),
              activeColor: Colors.cyan,
            ),
            const Text('إظهار السعر', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
          const Text('خيارات الملصق:', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _buildProductItem(ProductModel p, bool isDark) {
    final isSelected = _selectedIds.contains(p.id);
    final qty = _printQuantities[p.id] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? Colors.cyan : Colors.transparent, width: 1.5),
      ),
      child: Row(children: [
        // اختيار الكمية
        if (isSelected) Row(children: [
          _circleBtn(Icons.add, () => setState(() => _printQuantities[p.id!] = qty + 1)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          _circleBtn(Icons.remove, () {
            if (qty > 1) setState(() => _printQuantities[p.id!] = qty - 1);
          }),
        ]),
        const Spacer(),
        // معلومات المنتج
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(p.barcode ?? 'بدون باركود', style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text('${p.sellPrice} ر.ي', style: const TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(width: 12),
        Checkbox(
          value: isSelected,
          activeColor: Colors.cyan,
          onChanged: (v) {
            setState(() {
              if (v!) {
                _selectedIds.add(p.id!);
                _printQuantities[p.id!] = 1;
              } else {
                _selectedIds.remove(p.id);
              }
            });
          },
        ),
      ]),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.cyan.withOpacity(0.5))),
      child: Icon(icon, color: Colors.cyan, size: 16),
    ),
  );

  Widget _buildEmptyState(bool isDark) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.search_off, size: 60, color: isDark ? Colors.white10 : Colors.black12),
    const SizedBox(height: 16),
    const Text('لم يتم العثور على منتجات', style: TextStyle(color: Colors.grey)),
  ]));

  Widget _buildBottomAction(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _selectedIds.isEmpty ? null : _printBarcodes,
            icon: const Icon(Icons.print),
            label: Text('طباعة ${_selectedIds.length} ملصق مختار'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: Colors.white10,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _printBarcodes() async {
    final pp = context.read<ProductProvider>();
    List<Map<String, dynamic>> itemsToPrint = [];

    for (var id in _selectedIds) {
      final p = pp.products.firstWhere((prod) => prod.id == id);
      if (p.barcode == null || p.barcode!.isEmpty) continue;
      
      itemsToPrint.add({
        'name': p.name,
        'barcode': p.barcode,
        'price': p.sellPrice.toStringAsFixed(0),
        'qty': _printQuantities[id] ?? 1,
      });
    }

    if (itemsToPrint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار منتجات تحتوي على باركود أولاً')));
      return;
    }

    await PdfService.generateBarcodeLabels(items: itemsToPrint, showPrice: _showPrice);
  }
}
