import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/product_model.dart';
import '../models/product_unit_model.dart';
import '../provider/product_provider.dart';
import '../../settings/provider/currency_provider.dart';
import '../../../core/database/database_helper.dart';

class AddEditProductSheet extends StatefulWidget {
  final ProductModel? existing;
  const AddEditProductSheet({super.key, this.existing});
  @override
  State<AddEditProductSheet> createState() => _AddEditProductSheetState();
}

class _AddEditProductSheetState extends State<AddEditProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _barcode;
  late final TextEditingController _buyPrice;
  late final TextEditingController _sellPrice;
  late final TextEditingController _quantity;
  late final TextEditingController _lowAlert;
  late final TextEditingController _unit;
  late final TextEditingController _wholesalePrice;
  late final TextEditingController _category;
  int? _selectedCurrencyId;
  List<ProductUnitModel> _units = [];
  bool _isLiquid = false;
  bool _isByWeight = false;
  bool _scanMode = false;
  bool _saving = false;
  DateTime? _lastScanTime;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name      = TextEditingController(text: e?.name ?? '');
    _barcode   = TextEditingController(text: e?.barcode ?? '');
    _buyPrice  = TextEditingController(text: e != null ? e.buyPrice.toStringAsFixed(0) : '');
    _sellPrice = TextEditingController(text: e != null ? e.sellPrice.toStringAsFixed(0) : '');
    _quantity  = TextEditingController(text: e != null ? e.quantity.toStringAsFixed(0) : '');
    _lowAlert  = TextEditingController(text: e != null ? e.lowStockAlert.toStringAsFixed(0) : '5');
    _unit      = TextEditingController(text: e?.unit ?? 'قطعة');
    _wholesalePrice = TextEditingController(text: e != null ? e.wholesalePrice.toStringAsFixed(0) : '');
    _category  = TextEditingController(text: e?.category ?? 'عام');
    _isLiquid    = e?.isLiquid ?? false;
    _isByWeight  = e?.isByWeight ?? false;
    _selectedCurrencyId = e?.currencyId;
    _units = e?.units != null ? List.from(e!.units) : [];
    
    final cp = context.read<CurrencyProvider>();
    Future.microtask(() => cp.loadAll());
  }

  @override
  void dispose() {
    _scannerController.dispose();
    for (final c in [_name, _barcode, _buyPrice, _sellPrice, _quantity, _lowAlert, _unit, _category]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF111116), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          // Handle
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: BorderRadius.circular(8)),
              child: InkWell(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.white, size: 18))),
            const Spacer(),
            Text(isEdit ? 'تعديل المنتج' : 'إضافة منتج جديد', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            const Icon(Icons.inventory_2, color: Colors.cyan),
          ]),
          const SizedBox(height: 20),

          // ── Barcode field + scanner toggle
          _label('الباركود'),
          Row(children: [
            InkWell(
              onTap: () async {
                if (!_scanMode) {
                  final status = await Permission.camera.request();
                  if (!status.isGranted) return;
                }
                setState(() => _scanMode = !_scanMode);
              },
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _scanMode ? Colors.blueAccent : const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.qr_code_scanner, color: _scanMode ? Colors.white : Colors.white54, size: 22)),
            ),
            Expanded(child: _textField(_barcode, 'باركود المنتج', icon: Icons.qr_code)),
          ]),

          // ── Scanner preview
          if (_scanMode) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(height: 220, child: MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  final now = DateTime.now();
                  if (_lastScanTime != null && now.difference(_lastScanTime!) < const Duration(milliseconds: 1500)) {
                    return;
                  }

                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                    _lastScanTime = now;
                    HapticFeedback.lightImpact();
                    setState(() {
                      _barcode.text = barcodes.first.rawValue!;
                      _scanMode = false;
                    });
                  }
                },
              )),
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 12),
          _label('اسم المنتج *'),
          _textField(_name, 'مثال: مياه بلادي 500ml', icon: Icons.label_outline, required: true),
          const SizedBox(height: 16),

          // ── التصنيف (Autocomplete)
          _label('التصنيف'),
          _buildCategoryField(),
          const SizedBox(height: 16),

          // ── الأسعار
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _label('سعر البيع *'),
              _textField(_sellPrice, '0', icon: Icons.sell, type: TextInputType.number, required: true),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _label('سعر الشراء *'),
              _textField(_buyPrice, '0', icon: Icons.shopping_bag, type: TextInputType.number, required: true),
            ])),
          ]),
          const SizedBox(height: 16),

          // ── الكمية والتنبيه
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _label('تنبيه المخزون المنخفض'),
              _textField(_lowAlert, '5', icon: Icons.warning_amber, type: TextInputType.number),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _label('الكمية *'),
              _textField(_quantity, '0', icon: Icons.numbers, type: TextInputType.number, required: true),
            ])),
          ]),
          const SizedBox(height: 16),

          // ── عملة الشراء وسعر الجملة
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _label('سعر الجملة (ر.ي)'),
              _textField(_wholesalePrice, '0', icon: Icons.store, type: TextInputType.number),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _label('عملة الشراء'),
              _currencyDropdown(),
            ])),
          ]),
          const SizedBox(height: 16),

          // ── إدارة الوحدات (كرتون، رابطة...)
          _label('الوحدات الإضافية (اختياري)'),
          _buildUnitsList(),
          const SizedBox(height: 12),

          // ── الوحدة + السويتشات
          Row(children: [
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _label('وحدة القياس'),
              _textField(_unit, 'قطعة / لتر / كجم', icon: Icons.straighten),
            ])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _switchRow('منتج بالوزن', Icons.scale, _isByWeight, (v) => setState(() => _isByWeight = v))),
            const SizedBox(width: 8),
            Expanded(child: _switchRow('منتج سائل', Icons.water_drop, _isLiquid, (v) => setState(() => _isLiquid = v))),
          ]),

          // ── ربح متوقع
          if (_buyPrice.text.isNotEmpty && _sellPrice.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            _profitPreview(),
          ],

          const SizedBox(height: 24),
          // ── أزرار
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white70)))),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _saving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isEdit ? 'حفظ التعديلات' : 'إضافة المنتج', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
          ]),
        ])),
      )),
    );
  }

  Widget _buildCategoryField() {
    final pp = context.read<ProductProvider>();
    final allCategories = {'عام', ...pp.products.map((p) => p.category).where((c) => c.isNotEmpty)}.toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RawAutocomplete<String>(
        textEditingController: _category,
        focusNode: FocusNode(),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
          return allCategories.where((String option) => option.contains(textEditingValue.text));
        },
        onSelected: (String selection) {
          _category.text = selection;
        },
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'مثال: مشروبات، بسكويتات...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              suffixIcon: const Icon(Icons.category, color: Colors.white30, size: 18),
              filled: true,
              fillColor: const Color(0xFF1A1A24),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width - 40,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF22222E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(option, style: const TextStyle(color: Colors.white), textAlign: TextAlign.right),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(color: Colors.grey, fontSize: 12)));

  Widget _textField(TextEditingController c, String hint, {IconData? icon, TextInputType? type, bool required = false}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextFormField(
        controller: c,
        keyboardType: type,
        textAlign: TextAlign.right,
        style: const TextStyle(color: Colors.white),
        onChanged: (_) => setState(() {}), // refresh profit preview
        validator: required ? (v) => (v == null || v.isEmpty) ? 'مطلوب' : null : null,
        inputFormatters: type == TextInputType.number ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))] : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          suffixIcon: icon != null ? Icon(icon, color: Colors.white30, size: 18) : null,
          filled: true,
          fillColor: const Color(0xFF1A1A24),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _switchRow(String label, IconData icon, bool value, ValueChanged<bool> onChanged) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Switch(value: value, onChanged: onChanged, activeColor: Colors.cyan, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      Row(children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(width: 6),
        Icon(icon, color: Colors.white30, size: 16),
      ]),
    ]));

  Widget _currencyDropdown() {
    final currencies = context.watch<CurrencyProvider>().currencies;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedCurrencyId,
          dropdownColor: const Color(0xFF1A1A24),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white30),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          hint: const Text('اختر عملة', style: TextStyle(color: Colors.grey, fontSize: 12)),
          items: currencies.map((c) => DropdownMenuItem(
            value: c.id,
            child: Text('${c.name} (${c.code})'),
          )).toList(),
          onChanged: (v) => setState(() => _selectedCurrencyId = v),
        ),
      ),
    );
  }

  Widget _buildUnitsList() {
    return Column(
      children: [
        ..._units.map((u) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20), onPressed: () => setState(() => _units.remove(u))),
            const Spacer(),
            Text('${u.unitName} (يحتوي ${u.conversionFactor} ${_unit.text})', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        )),
        TextButton.icon(
          onPressed: _showAddUnitDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('إضافة وحدة (كرتون/رابطة...)'),
          style: TextButton.styleFrom(foregroundColor: Colors.cyan),
        ),
      ],
    );
  }

  void _showAddUnitDialog() {
    final nameCtrl = TextEditingController();
    final factorCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة وحدة قياس'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الوحدة (مثال: كرتون)')),
            TextField(controller: factorCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'كم حبة يحتوي؟')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final factor = double.tryParse(factorCtrl.text) ?? 0;
              if (nameCtrl.text.isNotEmpty && factor > 0) {
                setState(() => _units.add(ProductUnitModel(
                  productId: widget.existing?.id ?? 0,
                  unitName: nameCtrl.text,
                  conversionFactor: factor,
                )));
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Widget _profitPreview() {
    final rate = context.read<CurrencyProvider>().getRateFor(_selectedCurrencyId);
    final buyRaw  = double.tryParse(_buyPrice.text) ?? 0;
    final buyYer  = buyRaw * rate;
    final sell = double.tryParse(_sellPrice.text) ?? 0;
    final profit = sell - buyYer;
    final margin = buyYer > 0 ? (profit / buyYer * 100) : 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: profit >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (profit >= 0 ? Colors.green : Colors.red).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          if (_selectedCurrencyId != null && _selectedCurrencyId != 1) 
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('التكلفة باليمني: ${buyYer.toStringAsFixed(0)} ر.ي (بصرف $rate)', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Column(children: [
              Text('${margin.toStringAsFixed(1)}%', style: TextStyle(color: profit >= 0 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              const Text('هامش الربح', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ]),
            Column(children: [
              Text('${profit.toStringAsFixed(0)} ر.ي', style: TextStyle(color: profit >= 0 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              const Text('الربح للوحدة', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ]),
          ]),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final pp = context.read<ProductProvider>();
    final product = ProductModel(
      id: widget.existing?.id,
      name: _name.text.trim(),
      barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      buyPrice: double.tryParse(_buyPrice.text) ?? 0,
      sellPrice: double.tryParse(_sellPrice.text) ?? 0,
      wholesalePrice: double.tryParse(_wholesalePrice.text) ?? 0,
      quantity: double.tryParse(_quantity.text) ?? 0,
      unit: _unit.text.trim().isEmpty ? 'قطعة' : _unit.text.trim(),
      category: _category.text.trim().isEmpty ? 'عام' : _category.text.trim(),
      currencyId: _selectedCurrencyId,
      isLiquid: _isLiquid,
      isByWeight: _isByWeight,
      lowStockAlert: double.tryParse(_lowAlert.text) ?? 5,
      units: _units,
    );
    
    int? productId = widget.existing?.id;
    final ok = isEdit ? await pp.updateProduct(product) : await pp.addProduct(product);
    
    if (ok) {
      // حفظ الوحدات
      productId ??= pp.products.first.id;
      if (productId != null) {
        await DatabaseHelper.instance.insertProductUnits(productId, _units.map((u) => u.toMap()).toList());
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '✅ ${isEdit ? 'تم تعديل' : 'تمت إضافة'} المنتج بنجاح' : '❌ فشل الحفظ', textDirection: TextDirection.rtl),
      backgroundColor: ok ? Colors.green : Colors.red));
  }
}
