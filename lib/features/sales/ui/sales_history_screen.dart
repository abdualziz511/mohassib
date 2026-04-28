import 'package:flutter/material.dart';
import 'package:mohassib/core/database/database_helper.dart';
import 'package:mohassib/core/utils/pdf_service.dart';
import '../models/sales_models.dart';
import 'package:intl/intl.dart' hide TextDirection;

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});
  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<SaleModel> _sales = [];
  bool _loading = true;

  // فلاتر
  DateTimeRange? _dateRange;
  String _paymentMethod = 'الكل';
  final _customerCtrl = TextEditingController();

  static const _methods = ['الكل', 'cash', 'transfer', 'card', 'debt', 'split'];
  static const _methodLabels = {
    'الكل': 'الكل',
    'cash': 'نقداً',
    'transfer': 'تحويل',
    'card': 'بطاقة',
    'debt': 'آجل',
    'split': 'متعدد',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _customerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await DatabaseHelper.instance.getSalesFiltered(
      from: _dateRange?.start,
      to: _dateRange?.end,
      paymentMethod: _paymentMethod == 'الكل' ? null : _paymentMethod,
      customerName: _customerCtrl.text.trim().isEmpty ? null : _customerCtrl.text.trim(),
    );
    setState(() {
      _sales = data.map((m) => SaleModel.fromMap(m as Map<String, dynamic>)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _sales.fold<double>(0, (s, x) => s + x.totalAmount);
    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      appBar: AppBar(
        title: const Text('سجل المبيعات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.cyanAccent),
            tooltip: 'فلترة',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(children: [
        // ── شريط الفلاتر النشطة ──────────────────────────────────
        if (_dateRange != null || _paymentMethod != 'الكل' || _customerCtrl.text.isNotEmpty)
          _buildActiveFilters(),

        // ── ملخص ─────────────────────────────────────────────────
        _buildSummaryBar(total),

        // ── القائمة ──────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
              : _sales.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sales.length,
                        itemBuilder: (ctx, i) => _saleCard(_sales[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      color: const Color(0xFF1A1A24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.redAccent, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            setState(() {
              _dateRange = null;
              _paymentMethod = 'الكل';
              _customerCtrl.clear();
            });
            _load();
          },
          tooltip: 'إلغاء الفلاتر',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(spacing: 6, children: [
            if (_dateRange != null)
              _filterChip(
                '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}',
                Colors.blueAccent,
              ),
            if (_paymentMethod != 'الكل')
              _filterChip(_methodLabels[_paymentMethod] ?? _paymentMethod, Colors.orangeAccent),
            if (_customerCtrl.text.isNotEmpty)
              _filterChip(_customerCtrl.text, Colors.greenAccent),
          ]),
        ),
      ]),
    );
  }

  Widget _filterChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
  );

  Widget _buildSummaryBar(double total) {
    final fmt = NumberFormat('#,##0', 'ar');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A24),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('${_sales.length} فاتورة', style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const Spacer(),
        Text('الإجمالي: ', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        Text('${fmt.format(total)} ر.ي',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.history, color: Colors.white10, size: 80),
    const SizedBox(height: 16),
    const Text('لا توجد مبيعات تطابق الفلتر', style: TextStyle(color: Colors.white38, fontSize: 16)),
  ]));

  Widget _saleCard(SaleModel sale) {
    final date = DateTime.parse(sale.createdAt);
    final timeStr = DateFormat('hh:mm a').format(date);
    final dateStr = DateFormat('yyyy/MM/dd').format(date);
    final methodColor = _methodColor(sale.paymentMethod);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showSaleDetails(sale),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            // أيقونة طريقة الدفع
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: methodColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(SaleModel.methodIcon(sale.paymentMethod), color: methodColor, size: 22),
            ),
            const SizedBox(width: 14),
            // التفاصيل
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${sale.totalAmount.toStringAsFixed(0)} ر.ي',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('#${sale.saleNumber}', style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('$dateStr | $timeStr', style: const TextStyle(color: Colors.white24, fontSize: 11)),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: methodColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(SaleModel.methodLabel(sale.paymentMethod),
                        style: TextStyle(color: methodColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ]),
              if (sale.customerName != null && sale.customerName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('👤 ${sale.customerName}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ),
              ],
            ])),
          ]),
        ),
      ),
    );
  }

  Color _methodColor(String method) {
    switch (method) {
      case 'cash':     return Colors.greenAccent;
      case 'transfer': return Colors.blueAccent;
      case 'card':     return Colors.purpleAccent;
      case 'debt':     return Colors.orangeAccent;
      case 'split':    return Colors.tealAccent;
      default:         return Colors.grey;
    }
  }

  void _showSaleDetails(SaleModel sale) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Drag handle
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // عنوان
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(SaleModel.methodLabel(sale.paymentMethod),
                  style: TextStyle(color: _methodColor(sale.paymentMethod), fontWeight: FontWeight.bold)),
              Text('تفاصيل الفاتورة #${sale.saleNumber}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const Divider(color: Colors.white10, height: 24),

            // الأصناف
            Expanded(child: ListView(controller: scrollCtrl, children: [
              ...sale.items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Text('${it.total.toStringAsFixed(0)} ر.ي',
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('×${it.quantity}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(it.productName,
                      style: const TextStyle(color: Colors.white70), textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis)),
                ]),
              )),
            ])),

            const Divider(color: Colors.white10, height: 24),

            // الإجمالي
            if (sale.discount > 0)
              Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
                Text('- ${sale.discount.toStringAsFixed(0)} ر.ي',
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Text('خصم', style: TextStyle(color: Colors.grey)),
              ])),
            Row(children: [
              Text('${sale.totalAmount.toStringAsFixed(0)} ر.ي',
                  style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 20)),
              const Spacer(),
              const Text('الإجمالي النهائي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 20),

            // أزرار
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('إغلاق'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _handleReturn(sale),
                icon: const Icon(Icons.assignment_return_outlined, size: 18),
                label: const Text('إرجاع'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await PdfService.generateInvoice(sale, sale.items);
                },
                icon: const Icon(Icons.print, size: 18),
                label: const Text('طباعة'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  void _handleReturn(SaleModel sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        title: const Text('تأكيد الإرجاع', style: TextStyle(color: Colors.white), textDirection: TextDirection.rtl),
        content: Text('هل أنت متأكد من رغبتك في إرجاع الفاتورة #${sale.saleNumber} بالكامل؟ سيتم إعادة الأصناف للمخزون وخصم المبلغ من الصندوق.', 
            style: const TextStyle(color: Colors.grey), textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // إغلاق الديالوج
              Navigator.pop(context); // إغلاق المودال

              final itemsData = sale.items.map((it) => {
                'product_id': it.productId,
                'product_name': it.productName,
                'quantity': it.quantity,
                'price': it.sellPrice,
                'total': it.total,
              }).toList();

              await DatabaseHelper.instance.processReturn(
                saleId: sale.id!,
                saleNumber: sale.saleNumber.toString(),
                items: itemsData,
                totalAmount: sale.totalAmount,
                paymentMethod: sale.paymentMethod,
              );

              _load(); // إعادة تحميل القائمة
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('✅ تم إرجاع الفاتورة وإعادة الأصناف للمخزون', textDirection: TextDirection.rtl),
                  backgroundColor: Colors.green,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('تأكيد الإرجاع', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    final tmpCustomer = TextEditingController(text: _customerCtrl.text);
    DateTimeRange? tmpRange = _dateRange;
    String tmpMethod = _paymentMethod;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Center(child: Text('فلترة المبيعات',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 24),

            // نطاق التاريخ
            const Text('نطاق التاريخ', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: ctx,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                  initialDateRange: tmpRange,
                );
                if (picked != null) setSheet(() => tmpRange = picked);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111116),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tmpRange != null ? Colors.blueAccent.withOpacity(0.5) : Colors.white12),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  if (tmpRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.redAccent, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setSheet(() => tmpRange = null),
                    )
                  else
                    const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 18),
                  Text(
                    tmpRange == null
                        ? 'اختر نطاق التاريخ'
                        : '${DateFormat('dd/MM/yyyy').format(tmpRange!.start)} — ${DateFormat('dd/MM/yyyy').format(tmpRange!.end)}',
                    style: TextStyle(
                        color: tmpRange == null ? Colors.grey : Colors.white,
                        fontSize: 13),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // طريقة الدفع
            const Text('طريقة الدفع', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              alignment: WrapAlignment.end,
              children: _methods.map((m) {
                final isActive = tmpMethod == m;
                final label = _methodLabels[m] ?? m;
                return InkWell(
                  onTap: () => setSheet(() => tmpMethod = m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isActive ? Colors.blueAccent : Colors.white24),
                    ),
                    child: Text(label, style: TextStyle(
                        color: isActive ? Colors.blueAccent : Colors.white70,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // اسم العميل
            const Text('اسم العميل (اختياري)', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF111116), borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: tmpCustomer,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'ابحث باسم العميل...',
                  hintStyle: TextStyle(color: Colors.grey),
                  suffixIcon: Icon(Icons.person_search, color: Colors.cyan),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // أزرار
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () {
                  setState(() { _dateRange = null; _paymentMethod = 'الكل'; _customerCtrl.clear(); });
                  Navigator.pop(ctx);
                  _load();
                },
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('إعادة تعيين'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _dateRange = tmpRange;
                    _paymentMethod = tmpMethod;
                    _customerCtrl.text = tmpCustomer.text;
                  });
                  Navigator.pop(ctx);
                  _load();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('تطبيق الفلتر'),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}
