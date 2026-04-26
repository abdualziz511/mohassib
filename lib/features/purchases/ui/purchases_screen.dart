import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../products/provider/product_provider.dart';
import '../../suppliers/provider/supplier_provider.dart';
import '../provider/purchase_provider.dart';
import '../../products/models/product_model.dart';
import 'package:intl/intl.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final TextEditingController _invoiceCtrl = TextEditingController();
  final TextEditingController _paidCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SupplierProvider>().loadAll();
      context.read<ProductProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final purchaseProv = context.watch<PurchaseProvider>();
    final supplierProv = context.watch<SupplierProvider>();
    final productProv = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة مشتريات جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            onPressed: () => purchaseProv.clearCart(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Header: Supplier & Invoice Info
          _buildHeader(purchaseProv, supplierProv),

          const Divider(height: 1),

          // ── Product Search
          _buildProductSearch(productProv, purchaseProv),

          // ── Cart Items List
          Expanded(
            child: purchaseProv.cartItems.isEmpty
                ? _buildEmptyState()
                : _buildCartList(purchaseProv),
          ),

          // ── Bottom Summary & Actions
          _buildBottomSummary(purchaseProv, productProv),
        ],
      ),
    );
  }

  Widget _buildHeader(PurchaseProvider pProv, SupplierProvider sProv) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              value: pProv.selectedSupplierId,
              decoration: const InputDecoration(
                labelText: 'المورد',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('بدون مورد (نقدي)')),
                ...sProv.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
              ],
              onChanged: (val) => pProv.setSelectedSupplier(val),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _invoiceCtrl,
              decoration: const InputDecoration(
                labelText: 'رقم الفاتورة',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => pProv.setInvoiceNumber(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSearch(ProductProvider prodProv, PurchaseProvider purchProv) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'ابحث عن منتج بالاسم أو الباركود...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // TODO: Implement scanner
            },
          ),
          border: const UnderlineInputBorder(),
        ),
        onChanged: (val) {
          prodProv.searchProducts(val);
        },
        onSubmitted: (val) async {
          final p = await prodProv.getByBarcode(val);
          if (p != null) {
            _showAddProductDialog(p);
            _searchCtrl.clear();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('الفاتورة فارغة، ابدأ بإضافة أصناف', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCartList(PurchaseProvider pProv) {
    return ListView.builder(
      itemCount: pProv.cartItems.length,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        final item = pProv.cartItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('الكمية: ${item.quantity} ${item.unit} | السعر: ${item.buyPrice}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(NumberFormat.currency(symbol: '', decimalDigits: 0).format(item.total), 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => pProv.removeItem(item.productId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSummary(PurchaseProvider pProv, ProductProvider prodProv) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي الفاتورة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(NumberFormat.currency(symbol: 'ر.ي', decimalDigits: 0).format(pProv.totalAmount),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: pProv.isProcessing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text('حفظ الفاتورة', style: TextStyle(fontSize: 18)),
                    onPressed: pProv.isProcessing || pProv.cartItems.isEmpty || pProv.invoiceNumber.isEmpty
                        ? null 
                        : () async {
                            final ok = await pProv.savePurchase(prodProv);
                            if (ok) {
                              _invoiceCtrl.clear();
                              _paidCtrl.clear();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')));
                            }
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog(ProductModel p) {
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: p.buyPrice.toString());
    String selectedUnit = p.unit;
    double factor = 1.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('إضافة: ${p.name}', textAlign: TextAlign.right),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // اختيار الوحدة
              DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration: const InputDecoration(labelText: 'الوحدة'),
                items: [
                  DropdownMenuItem(value: p.unit, child: Text(p.unit)),
                  ...p.units.map((u) => DropdownMenuItem(value: u.unitName, child: Text(u.unitName))),
                ],
                onChanged: (val) {
                  setDialogState(() {
                    selectedUnit = val!;
                    if (selectedUnit == p.unit) {
                      factor = 1.0;
                      priceCtrl.text = p.buyPrice.toString();
                    } else {
                      final u = p.units.firstWhere((ux) => ux.unitName == selectedUnit);
                      factor = u.conversionFactor;
                      priceCtrl.text = (p.buyPrice * factor).toString();
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الكمية'),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'سعر شراء الوحدة'),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                final qty = double.tryParse(qtyCtrl.text) ?? 0;
                final price = double.tryParse(priceCtrl.text) ?? 0;
                if (qty > 0 && price > 0) {
                  context.read<PurchaseProvider>().addProductToCart(p, qty, price, unit: selectedUnit, factor: factor);
                  Navigator.pop(context);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }
}
