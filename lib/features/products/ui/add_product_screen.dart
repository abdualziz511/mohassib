import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/product_model.dart';
import '../models/product_unit_model.dart';
import '../provider/product_provider.dart';
import '../../settings/provider/currency_provider.dart';

enum ProductUiType { standard, bulk, weighted, liquid }

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

  // Smart Unit Controllers
  late final TextEditingController _bulkUnitName;
  late final TextEditingController _bulkFactor;

  ProductUiType _uiType = ProductUiType.standard;
  int? _selectedCurrencyId;
  List<ProductUnitModel> _units = [];
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
    _name = TextEditingController(text: e?.name ?? '');
    _barcode = TextEditingController(text: e?.barcode ?? '');
    _buyPrice = TextEditingController(text: e != null ? e.buyPrice.toStringAsFixed(0) : '');
    _sellPrice = TextEditingController(text: e != null ? e.sellPrice.toStringAsFixed(0) : '');
    _quantity = TextEditingController(text: e != null ? e.quantity.toStringAsFixed(0) : '');
    _lowAlert = TextEditingController(text: e != null ? e.lowStockAlert.toStringAsFixed(0) : '5');
    _unit = TextEditingController(text: e?.unit ?? 'حبة');
    _wholesalePrice = TextEditingController(text: e != null ? e.wholesalePrice.toStringAsFixed(0) : '');
    _category = TextEditingController(text: e?.category ?? 'عام');

    _bulkUnitName = TextEditingController(text: 'كرتون');
    _bulkFactor = TextEditingController(text: '24');

    _selectedCurrencyId = e?.currencyId;
    _units = e?.units != null ? List.from(e!.units) : [];

    // Determine UI Type from existing data
    if (e != null) {
      if (e.isByWeight) _uiType = ProductUiType.weighted;
      else if (e.isLiquid) _uiType = ProductUiType.liquid;
      else if (e.units.isNotEmpty) _uiType = ProductUiType.bulk;
    }

    final cp = context.read<CurrencyProvider>();
    Future.microtask(() => cp.loadAll());
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _name.dispose(); _barcode.dispose(); _buyPrice.dispose(); _sellPrice.dispose();
    _quantity.dispose(); _lowAlert.dispose(); _unit.dispose(); _category.dispose();
    _bulkUnitName.dispose(); _bulkFactor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F13),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildTypeSelector(),
                      const SizedBox(height: 24),
                      _sectionTitle('المعلومات الأساسية', Icons.info_outline),
                      _buildBasicInfo(),
                      const SizedBox(height: 24),
                      _sectionTitle('الأسعار والمخزون', Icons.payments_outlined),
                      _buildPricingInfo(),
                      const SizedBox(height: 24),
                      _buildSmartUnitSection(),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Column(
    children: [
      const SizedBox(height: 12),
      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54),
              onPressed: () => Navigator.pop(context),
            ),
            Text(
              isEdit ? 'تعديل المنتج' : 'إضافة منتج جديد',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const Icon(Icons.inventory_2, color: Colors.cyan, size: 28),
          ],
        ),
      ),
    ],
  );

  Widget _buildTypeSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      const Text('نوع المنتج', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          children: [
            _typeCard('عادي', Icons.shopping_bag_outlined, ProductUiType.standard),
            _typeCard('جملة/عبوة', Icons.inventory_2_outlined, ProductUiType.bulk),
            _typeCard('بالوزن', Icons.scale_outlined, ProductUiType.weighted),
            _typeCard('سائل', Icons.water_drop_outlined, ProductUiType.liquid),
          ],
        ),
      ),
    ],
  );

  Widget _typeCard(String label, IconData icon, ProductUiType type) {
    final isSel = _uiType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _uiType = type;
          if (type == ProductUiType.weighted) _unit.text = 'كيلو';
          else if (type == ProductUiType.liquid) _unit.text = 'لتر';
          else if (type == ProductUiType.standard) _unit.text = 'حبة';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? Colors.cyan.withOpacity(0.1) : const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? Colors.cyan : Colors.transparent, width: 2),
          boxShadow: isSel ? [BoxShadow(color: Colors.cyan.withOpacity(0.2), blurRadius: 8)] : null,
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: isSel ? Colors.cyan : Colors.white60, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(icon, color: isSel ? Colors.cyan : Colors.white30, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Icon(icon, color: Colors.cyan, size: 18),
      ],
    ),
  );

  Widget _buildBasicInfo() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(20)),
    child: Column(
      children: [
        _textField(_name, 'اسم المنتج (مثال: أرز الشعلان 10كجم)', icon: Icons.edit, required: true),
        const SizedBox(height: 12),
        Row(
          children: [
            InkWell(
              onTap: _toggleScanner,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _scanMode ? Colors.redAccent.withOpacity(0.2) : Colors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _scanMode ? Colors.redAccent : Colors.cyan.withOpacity(0.3)),
                ),
                child: Icon(_scanMode ? Icons.stop : Icons.qr_code_scanner, color: _scanMode ? Colors.redAccent : Colors.cyan),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _textField(_barcode, 'الباركود (اختياري)', icon: Icons.qr_code)),
          ],
        ),
        if (_scanMode) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(height: 180, child: MobileScanner(
              controller: _scannerController,
              onDetect: _onBarcodeDetect,
            )),
          ),
        ],
        const SizedBox(height: 12),
        _buildCategoryAutocomplete(),
      ],
    ),
  );

  Widget _buildPricingInfo() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(20)),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: _textField(_sellPrice, 'سعر البيع', icon: Icons.sell, type: TextInputType.number, required: true)),
            const SizedBox(width: 12),
            Expanded(child: _textField(_buyPrice, 'سعر الشراء', icon: Icons.shopping_bag, type: TextInputType.number, required: true)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _textField(_lowAlert, 'تنبيه المخزون', icon: Icons.warning_amber, type: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _textField(_quantity, 'الكمية الحالية', icon: Icons.inventory, type: TextInputType.number, required: true)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _currencyDropdown()),
            const SizedBox(width: 12),
            Expanded(child: _textField(_unit, 'الوحدة الأساسية', icon: Icons.straighten)),
          ],
        ),
        const SizedBox(height: 16),
        _profitPreview(),
      ],
    ),
  );

  Widget _buildSmartUnitSection() {
    if (_uiType == ProductUiType.standard) return const SizedBox.shrink();

    return Column(
      children: [
        _sectionTitle('إعدادات العبوة والجملة', Icons.auto_awesome),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.cyan.withOpacity(0.05), Colors.blue.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.cyan.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(flex: 2, child: _textField(_bulkFactor, 'تحتوي على كم؟', type: TextInputType.number, icon: Icons.numbers)),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: _textField(_bulkUnitName, 'اسم العبوة (كرتون/كيس)', icon: Icons.box)),
                ],
              ),
              const SizedBox(height: 12),
              _smartUnitHint(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _smartUnitHint() {
    final factor = double.tryParse(_bulkFactor.text) ?? 1;
    final sell = double.tryParse(_sellPrice.text) ?? 0;
    final bulkPrice = sell * factor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'سيتم بيع الـ ${_bulkUnitName.text} بـ ${bulkPrice.toStringAsFixed(0)} ر.ي تلقائياً',
            style: const TextStyle(color: Colors.cyan, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.lightbulb_outline, color: Colors.cyan, size: 14),
        ],
      ),
    );
  }

  Widget _buildActionButtons() => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white24),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: Colors.cyan.withOpacity(0.5),
          ),
          child: _saving 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(isEdit ? 'حفظ التعديلات' : 'إضافة المنتج', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      ),
    ],
  );

  // ── Helper Widgets ──

  Widget _textField(TextEditingController c, String hint, {IconData? icon, TextInputType? type, bool required = false}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextFormField(
        controller: c,
        keyboardType: type,
        textAlign: TextAlign.right,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        onChanged: (_) => setState(() {}),
        validator: required ? (v) => (v == null || v.isEmpty) ? 'مطلوب' : null : null,
        inputFormatters: type == TextInputType.number ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))] : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
          suffixIcon: icon != null ? Icon(icon, color: Colors.white24, size: 18) : null,
          filled: true,
          fillColor: const Color(0xFF111116),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.cyan, width: 1)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryAutocomplete() {
    final pp = context.read<ProductProvider>();
    final allCategories = {'عام', ...pp.products.map((p) => p.category).where((c) => c.isNotEmpty)}.toList();

    return RawAutocomplete<String>(
      textEditingController: _category,
      optionsBuilder: (v) => v.text.isEmpty ? const Iterable<String>.empty() : allCategories.where((o) => o.contains(v.text)),
      onSelected: (s) => _category.text = s,
      fieldViewBuilder: (ctx, ctrl, focus, onSubmitted) => _textField(ctrl, 'التصنيف (مثال: معلبات، منظفات...)', icon: Icons.category),
      optionsViewBuilder: (ctx, onSel, options) => Align(
        alignment: Alignment.topRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width - 72,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(color: const Color(0xFF22222E), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.cyan.withOpacity(0.3))),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(options.elementAt(i), style: const TextStyle(color: Colors.white)),
                onTap: () => onSel(options.elementAt(i)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _currencyDropdown() {
    final currencies = context.watch<CurrencyProvider>().currencies;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF111116), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedCurrencyId,
          dropdownColor: const Color(0xFF1A1A24),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white24),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          hint: const Text('عملة الشراء', style: TextStyle(color: Colors.white24, fontSize: 12)),
          items: currencies.map((c) => DropdownMenuItem(value: c.id, child: Text(c.code))).toList(),
          onChanged: (v) => setState(() => _selectedCurrencyId = v),
        ),
      ),
    );
  }

  Widget _profitPreview() {
    final rate = context.read<CurrencyProvider>().getRateFor(_selectedCurrencyId);
    final buyRaw = double.tryParse(_buyPrice.text) ?? 0;
    final buyYer = buyRaw * rate;
    final sell = double.tryParse(_sellPrice.text) ?? 0;
    final profit = sell - buyYer;
    final margin = buyYer > 0 ? (profit / buyYer * 100) : 0;
    final isGood = profit >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGood ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isGood ? Colors.green : Colors.red).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _profitStat('${margin.toStringAsFixed(1)}%', 'هامش الربح', isGood ? Colors.greenAccent : Colors.redAccent),
          Container(width: 1, height: 30, color: Colors.white10),
          _profitStat('${profit.toStringAsFixed(0)} ر.ي', 'الربح الصافي', isGood ? Colors.greenAccent : Colors.redAccent),
        ],
      ),
    );
  }

  Widget _profitStat(String val, String label, Color color) => Column(
    children: [
      Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    ],
  );

  // ── Logic ──

  void _toggleScanner() async {
    if (!_scanMode) {
      final status = await Permission.camera.request();
      if (!status.isGranted) return;
    }
    setState(() => _scanMode = !_scanMode);
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    final now = DateTime.now();
    if (_lastScanTime != null && now.difference(_lastScanTime!) < const Duration(milliseconds: 1500)) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      _lastScanTime = now;
      HapticFeedback.lightImpact();
      setState(() {
        _barcode.text = barcodes.first.rawValue!;
        _scanMode = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final pp = context.read<ProductProvider>();
    
    // Prepare Units
    List<ProductUnitModel> finalUnits = [];
    if (_uiType == ProductUiType.bulk) {
      final factor = double.tryParse(_bulkFactor.text) ?? 1;
      finalUnits.add(ProductUnitModel(
        productId: widget.existing?.id ?? 0,
        unitName: _bulkUnitName.text.trim().isEmpty ? 'عبوة' : _bulkUnitName.text.trim(),
        conversionFactor: factor,
        isSaleUnit: true,
        isPurchaseUnit: true,
      ));
    }

    final product = ProductModel(
      id: widget.existing?.id,
      name: _name.text.trim(),
      barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      buyPrice: double.tryParse(_buyPrice.text) ?? 0,
      sellPrice: double.tryParse(_sellPrice.text) ?? 0,
      wholesalePrice: double.tryParse(_wholesalePrice.text) ?? 0,
      quantity: double.tryParse(_quantity.text) ?? 0,
      unit: _unit.text.trim(),
      category: _category.text.trim().isEmpty ? 'عام' : _category.text.trim(),
      currencyId: _selectedCurrencyId,
      isLiquid: _uiType == ProductUiType.liquid,
      isByWeight: _uiType == ProductUiType.weighted,
      lowStockAlert: double.tryParse(_lowAlert.text) ?? 5,
    );

    final ok = isEdit 
      ? await pp.updateProduct(product, finalUnits) 
      : await pp.addProduct(product, finalUnits);

    if (!mounted) return;
    setState(() => _saving = false);
    
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ ${isEdit ? 'تم تحديل' : 'تمت إضافة'} المنتج بنجاح', textDirection: TextDirection.rtl),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ فشل الحفظ', textDirection: TextDirection.rtl), backgroundColor: Colors.red));
    }
  }
}
