import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mohassib/features/products/models/product_model.dart';
import 'package:mohassib/features/products/provider/product_provider.dart';
import 'package:mohassib/features/sales/models/sales_models.dart';
import 'package:mohassib/features/customers/provider/customer_provider.dart';
import 'package:mohassib/core/utils/pdf_service.dart';
import 'package:mohassib/features/debts/models/debt_model.dart';
import 'package:mohassib/features/home/home_provider.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});
  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  bool _scanMode = false;
  DateTime? _lastScanTime;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      body: SafeArea(child: Column(children: [
        _appBar(context, cart),
        if (_scanMode) _scannerView(context, cart),
        _cartHeader(context),
        cart.isEmpty ? _emptyState() : _cartList(cart),
        _bottomBar(context, cart),
      ])),
    );
  }

  Widget _appBar(BuildContext context, CartProvider cart) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(
        child: Row(children: [
          _iconBtn(Icons.fullscreen, Colors.grey),
          const SizedBox(width: 8),
          Flexible(
            child: PopupMenuButton<int>(
              onSelected: (idx) => cart.switchSession(idx),
              offset: const Offset(0, 40),
              itemBuilder: (ctx) => List.generate(5, (i) {
                final session = cart.sessions[i];
                final isCurrent = cart.currentSessionIndex == i;
                return PopupMenuItem(
                  value: i,
                  child: Row(children: [
                    if (isCurrent) const Icon(Icons.check_circle, color: Colors.blueAccent, size: 16),
                    const SizedBox(width: 8),
                    Text('السلة ${i + 1}', style: TextStyle(color: isCurrent ? Colors.blueAccent : Colors.white, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                    const Spacer(),
                    if (session.items.isNotEmpty) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text('${session.items.length}', style: const TextStyle(color: Colors.blueAccent, fontSize: 10)),
                    ),
                  ]),
                );
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blueAccent.withOpacity(0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.arrow_drop_down, color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 4),
                  Flexible(child: FittedBox(child: Text('السلة ${cart.currentSessionIndex + 1}', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)))),
                  if (cart.itemCount > 0) ...[
                    const SizedBox(width: 4),
                    CircleAvatar(radius: 9, backgroundColor: Colors.blueAccent, child: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                  ],
                ]),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(width: 8),
      const FittedBox(child: Text('نقطة البيع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
      const SizedBox(width: 8),
      InkWell(onTap: () => Navigator.pop(context), child: const Icon(Icons.history, color: Colors.blueAccent, size: 22)),
    ]),
  );

  Widget _cartHeader(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(
        child: Row(children: [
          InkWell(
            onTap: () => _showGallery(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFF1E2433), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add, color: Colors.blueAccent, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () async {
                if (!_scanMode) {
                  final status = await Permission.camera.request();
                  if (!status.isGranted) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يجب السماح بالوصول للكاميرا للمسح', textDirection: TextDirection.rtl), backgroundColor: Colors.orange)
                      );
                    }
                    return;
                  }
                }
                setState(() => _scanMode = !_scanMode);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _scanMode ? Colors.blueAccent : const Color(0xFF1E2433),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                  Flexible(child: FittedBox(child: Text(_scanMode ? 'إيقاف المسح' : 'مسح باركود', style: TextStyle(color: _scanMode ? Colors.white : Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)))),
                  const SizedBox(width: 4),
                  Icon(Icons.qr_code_scanner, color: _scanMode ? Colors.white : Colors.blueAccent, size: 16),
                ]),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(width: 12),
      const FittedBox(child: Text('سلة المشتريات', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
    ]),
  );

  Widget _scannerView(BuildContext context, CartProvider cart) => Container(
    margin: const EdgeInsets.all(16),
    height: 200,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blueAccent, width: 2)),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: MobileScanner(
        controller: _scannerController,
        onDetect: (capture) {
          final now = DateTime.now();
          if (_lastScanTime != null && now.difference(_lastScanTime!) < const Duration(milliseconds: 1500)) {
            return;
          }

          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            _lastScanTime = now;
            final code = barcodes.first.rawValue!;
            final pp = context.read<ProductProvider>();
            final product = pp.products.firstWhere((p) => p.barcode == code, orElse: () => ProductModel(id: -1, name: '', sellPrice: 0, buyPrice: 0, quantity: 0));
            
            if (product.id != -1) {
              HapticFeedback.mediumImpact();
              cart.addProduct(product);
              // Show quick info
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('تمت إضافة: ${product.name}', textDirection: TextDirection.rtl),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.green,
              ));
            } else {
              HapticFeedback.vibrate();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('المنتج غير موجود!', textDirection: TextDirection.rtl),
                duration: Duration(seconds: 1),
                backgroundColor: Colors.red,
              ));
            }
          }
        },
      ),
    ),
  );

  Widget _emptyState() => Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.qr_code_scanner, color: Colors.grey.shade600, size: 80),
    const SizedBox(height: 16),
    Text('ابدأ المسح أو اضغط إضافة منتجات', style: TextStyle(color: Colors.grey.shade400)),
  ])));

  Widget _cartList(CartProvider cart) => Expanded(child: ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    itemCount: cart.items.length,
    itemBuilder: (ctx, i) {
      final item = cart.items[i];
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          InkWell(
            onTap: () => cart.removeItem(item.productId),
            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20)),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _showQtyDialog(item),
            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF162A32), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.edit, color: Colors.blueAccent, size: 20)),
          ),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('${item.sellPrice.toStringAsFixed(0)} ر.ي × ${item.quantity}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            Text('= ${item.lineTotal.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
          ]),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _showUnitSelector(context, item, cart),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF22222E), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blueAccent.withOpacity(0.3))),
              child: Text(item.unit, style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      );
    },
  ));

  Widget _bottomBar(BuildContext context, CartProvider cart) {
    if (cart.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: const BoxDecoration(color: Color(0xFF1A1A24), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: SafeArea(child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
          child: const Center(child: Text('السلة فارغة', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18))),
        )),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Color(0xFF1A1A24), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (cart.discount > 0 || cart.taxAmount > 0) 
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              if (cart.taxAmount > 0) Row(children: [
                Text('${cart.taxAmount.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                const Text(' :ضريبة', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ]),
              if (cart.discount > 0) Row(children: [
                Text('${cart.discount.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                const Text(' :خصم', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ]),
            ]),
          ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: ElevatedButton(
            onPressed: () => _showPayment(context, cart),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const FittedBox(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('إتمام البيع', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            ),
          )),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${cart.itemCount} صنف', style: const TextStyle(color: Colors.grey, fontSize: 10)),
            FittedBox(child: Text('${cart.total.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
          ]),
        ]),
      ])),
    );
  }

  Widget _iconBtn(IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(8)),
    child: Icon(icon, color: color, size: 20),
  );

  void _showGallery(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ProductProvider>(),
        child: _ProductGallery(onAdd: (p) => context.read<CartProvider>().addProduct(p)),
      ));
  }

  void _showQtyDialog(CartItem item) {
    showDialog(context: context, builder: (_) => _QtyDialog(item: item, cart: context.read<CartProvider>()));
  }

  void _showPayment(BuildContext context, CartProvider cart) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cart),
          ChangeNotifierProvider.value(value: context.read<ProductProvider>()),
        ],
        child: const _PaymentSheet(),
      ));
  }
}

// ── Gallery Sheet ──────────────────────────────────────────────
class _ProductGallery extends StatefulWidget {
  final void Function(ProductModel) onAdd;
  const _ProductGallery({required this.onAdd});
  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final list = _q.isEmpty ? pp.products : pp.products.where((p) => p.name.contains(_q) || (p.barcode ?? '').contains(_q)).toList();
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Color(0xFF111116), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          InkWell(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.white)),
          const Text('معرض المنتجات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(
          textAlign: TextAlign.right,
          style: const TextStyle(color: Colors.white),
          onChanged: (v) => setState(() => _q = v.trim()),
          decoration: InputDecoration(
            hintText: 'بحث باسم أو باركود...',
            hintStyle: const TextStyle(color: Colors.grey),
            suffixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true, fillColor: const Color(0xFF1A1A24),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        )),
        const SizedBox(height: 12),
        Expanded(child: list.isEmpty
          ? const Center(child: Text('لا توجد منتجات', style: TextStyle(color: Colors.grey)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
              itemCount: list.length,
              itemBuilder: (ctx, i) {
                final p = list[i];
                return Container(
                  decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    Expanded(child: Container(decoration: const BoxDecoration(color: Color(0xFF22222E), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                      child: Stack(children: [
                        const Center(child: Icon(Icons.inventory_2, color: Colors.grey, size: 40)),
                        Positioned(top: 8, right: 8, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: p.isOutOfStock ? Colors.red : (p.isLowStock ? Colors.orange : Colors.green), borderRadius: BorderRadius.circular(8)),
                          child: Text('${p.quantity} ${p.unit}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )),
                      ]))),
                    Padding(padding: const EdgeInsets.all(10), child: Column(children: [
                      Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                      Text('${p.sellPrice.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.cyan, fontSize: 11)),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: OutlinedButton(
                        onPressed: p.isOutOfStock ? null : () { widget.onAdd(p); Navigator.pop(context); },
                        style: OutlinedButton.styleFrom(side: BorderSide(color: p.isOutOfStock ? Colors.grey : Colors.blueAccent.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: Text(p.isOutOfStock ? 'نفذ' : 'إضافة', style: TextStyle(color: p.isOutOfStock ? Colors.grey : Colors.blueAccent, fontWeight: FontWeight.bold)),
                      )),
                    ])),
                  ]),
                );
              },
            )),
      ]),
    );
  }
}

// ── Qty Dialog ─────────────────────────────────────────────────
class _QtyDialog extends StatefulWidget {
  final CartItem item;
  final CartProvider cart;
  const _QtyDialog({required this.item, required this.cart});
  @override
  State<_QtyDialog> createState() => _QtyDialogState();
}
class _QtyDialogState extends State<_QtyDialog> {
  late double _qty;
  late double _price;
  @override
  void initState() { super.initState(); _qty = widget.item.quantity; _price = widget.item.sellPrice; }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(widget.item.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: () { if (_qty > 1) setState(() => _qty--); }, icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 32)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_qty.toStringAsFixed(_qty % 1 == 0 ? 0 : 2), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold))),
          IconButton(
            onPressed: () { 
              if ((_qty + 1) * widget.item.conversionFactor <= widget.item.maxQuantity) {
                setState(() => _qty++); 
              }
            }, 
            icon: const Icon(Icons.add_circle, color: Colors.greenAccent, size: 32)
          ),
        ]),
        Text(widget.item.unit, style: const TextStyle(color: Colors.grey)),
        const Divider(color: Colors.white10, height: 32),
        Text('الإجمالي: ${(_price * _qty).toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () { widget.cart.updateQuantity(widget.item.productId, _qty); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('تأكيد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
        ]),
      ])),
    );
  }
}

// ── Payment Sheet ──────────────────────────────────────────────
class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet();
  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}
class _PaymentSheetState extends State<_PaymentSheet> {
  String _method = 'cash';
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  int? _selectedCustomerId;

  static const _methods = [
    {'key': 'cash',     'label': 'نقداً',              'icon': Icons.money,                  'color': Colors.green},
    {'key': 'transfer', 'label': 'تحويل بنكي',         'icon': Icons.account_balance_wallet, 'color': Colors.blue},
    {'key': 'card',     'label': 'بطاقة إئتمانية',     'icon': Icons.credit_card,            'color': Colors.purple},
    {'key': 'debt',     'label': 'بيع بالآجل (دين)',   'icon': Icons.menu_book,              'color': Colors.orange},
    {'key': 'split',    'label': 'دفع متعدد',           'icon': Icons.call_split,             'color': Colors.purpleAccent},
  ];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF1E1E2A), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 16),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const SizedBox(width: 56),
          Column(children: [
            const Text('طريقة الدفع', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${cart.total.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
          IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 8),
        ...(_methods.map((m) {
          final isActive = _method == m['key'];
          return InkWell(
            onTap: () => setState(() => _method = m['key'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? (m['color'] as Color).withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isActive ? Border.all(color: (m['color'] as Color).withOpacity(0.4)) : null,
              ),
              child: Row(children: [
                if (isActive) Icon(Icons.check_circle, color: m['color'] as Color, size: 20) else const SizedBox(width: 20),
                const Spacer(),
                Text(m['label'] as String, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (m['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Icon(m['icon'] as IconData, color: m['color'] as Color, size: 20)),
              ]),
            ),
          );
        })).toList(),
        if (_method == 'debt') Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Column(children: [
          Consumer<CustomerProvider>(
            builder: (ctx, custProv, _) {
              if (custProv.customers.isEmpty) {
                return const Text('لا يوجد عملاء مضافين، يرجى إضافة عميل من شاشة العملاء', style: TextStyle(color: Colors.redAccent, fontSize: 12));
              }
              
              // عرض حقل البحث مع الاقتراحات
              final suggestions = _nameCtrl.text.isEmpty ? [] : custProv.customers.where((c) => c.name.contains(_nameCtrl.text)).toList();
              
              return Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن عميل أو اكتب اسم جديد...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      suffixIcon: const Icon(Icons.person_search, color: Colors.cyan),
                      filled: true, fillColor: const Color(0xFF111116),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                  if (suggestions.isNotEmpty && _selectedCustomerId == null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(color: const Color(0xFF111116), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: suggestions.take(3).map((c) => ListTile(
                          dense: true,
                          title: Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          subtitle: Text('رصيد: ${c.currentBalance.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          onTap: () {
                            setState(() {
                              _selectedCustomerId = c.id;
                              _nameCtrl.text = c.name;
                              _phoneCtrl.text = c.phone ?? '';
                            });
                          },
                        )).toList(),
                      ),
                    ),
                  if (_selectedCustomerId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('تم اختيار: ${_nameCtrl.text}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                            onPressed: () => setState(() {
                              _selectedCustomerId = null;
                              _nameCtrl.clear();
                              _phoneCtrl.clear();
                            }),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          _field(_phoneCtrl, 'رقم الهاتف (اختياري)', Icons.phone, type: TextInputType.phone),
        ])),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: cart.isProcessing ? null : () => _confirm(context, cart),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: cart.isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('تأكيد البيع', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ))),
      ]))),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon, {TextInputType? type}) => Container(
    decoration: BoxDecoration(color: const Color(0xFF111116), borderRadius: BorderRadius.circular(12)),
    child: TextField(controller: c, textAlign: TextAlign.right, keyboardType: type, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.grey), suffixIcon: Icon(icon, color: Colors.cyan), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))));

  Future<void> _confirm(BuildContext context, CartProvider cart) async {
    final pp = context.read<ProductProvider>();
    
    // حفظ نسخة من العناصر للطباعة قبل مسح السلة
    final itemsToPrint = cart.items.map((i) => SaleItemModel(
      saleId: 0,
      productId: i.productId,
      productName: i.name,
      buyPrice: i.buyPrice,
      sellPrice: i.sellPrice,
      quantity: i.quantity,
      total: i.lineTotal,
    )).toList();

    final totalAmount = cart.total;
    final discount = cart.discount;
    final taxAmount = cart.taxAmount;

    final saleId = await cart.checkout(
      paymentMethod: _method,
      productProvider: pp,
      customerName: _nameCtrl.text.isEmpty ? null : _nameCtrl.text,
      customerPhone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
      customerId: _selectedCustomerId,
    );

    if (!mounted) return;
    Navigator.pop(context); // close payment sheet
    if (saleId != null) {
      // تحديث قائمة العملاء والديون والتقارير لضمان مزامنة البيانات
      context.read<CustomerProvider>().loadAll();
      context.read<DebtProvider>().loadAll();
      context.read<HomeProvider>().refresh();

      final sale = SaleModel(
        id: saleId,
        saleNumber: saleId,
        totalAmount: totalAmount,
        discount: discount,
        taxAmount: taxAmount,
        paymentMethod: _method,
        customerName: _nameCtrl.text.isEmpty ? null : _nameCtrl.text,
        customerPhone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
        createdAt: DateTime.now().toIso8601String(),
        items: itemsToPrint,
      );
      _showSuccess(context, sale);
    } else if (cart.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ ${cart.lastError}', textDirection: TextDirection.rtl),
        backgroundColor: Colors.red));
    }
  }

  void _showSuccess(BuildContext context, SaleModel sale) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
          const SizedBox(height: 16),
          const Text('تمت العملية بنجاح!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('رقم الفاتورة: #${sale.id}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx); 
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('إغلاق', style: TextStyle(color: Colors.white70)))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () async {
                await PdfService.generateInvoice(sale, sale.items);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.print, size: 18),
                SizedBox(width: 4),
                Text('طباعة', style: TextStyle(fontWeight: FontWeight.bold)),
              ]))),
          ]),
        ]),
      ),
    );
  }
}

// ── Unit Selector Sheet ────────────────────────────────────────
void _showUnitSelector(BuildContext context, CartItem item, CartProvider cart) {
  final pp = context.read<ProductProvider>();
  final product = pp.products.firstWhere((p) => p.id == item.productId);
  
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A24),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('اختر وحدة البيع', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // الوحدة الأساسية
          ListTile(
            title: Text(product.unit, style: const TextStyle(color: Colors.white)),
            subtitle: Text('السعر: ${product.sellPrice.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.grey)),
            trailing: item.unit == product.unit ? const Icon(Icons.check_circle, color: Colors.blueAccent) : null,
            onTap: () {
              cart.updateUnit(item.productId, product.unit, 1.0, product.sellPrice);
              Navigator.pop(ctx);
            },
          ),
          // الوحدات المضافة
          ...product.units.map((u) => ListTile(
            title: Text(u.unitName, style: const TextStyle(color: Colors.white)),
            subtitle: Text('يحتوي ${u.conversionFactor} ${product.unit} | السعر: ${(product.sellPrice * u.conversionFactor + u.priceMarkup).toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.grey)),
            trailing: item.unit == u.unitName ? const Icon(Icons.check_circle, color: Colors.blueAccent) : null,
            onTap: () {
              final newPrice = (product.sellPrice * u.conversionFactor) + u.priceMarkup;
              cart.updateUnit(item.productId, u.unitName, u.conversionFactor, newPrice);
              Navigator.pop(ctx);
            },
          )),
        ],
      ),
    ),
  );
}

