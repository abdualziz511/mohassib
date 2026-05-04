import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mohassib/features/expenses/models/expense_model.dart';
import 'package:mohassib/features/expenses/ui/expense_categories_screen.dart';
import 'package:mohassib/features/home/home_provider.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<ExpenseProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      body: SafeArea(child: Column(children: [
        _header(context, ep),
        _filterRow(context, ep),
        const SizedBox(height: 8),
        ep.isLoading
          ? const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.cyan)))
          : ep.expenses.isEmpty
            ? _empty()
            : Expanded(child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ep.expenses.length,
                itemBuilder: (_, i) => _card(context, ep.expenses[i], ep),
              )),
      ])),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E1E2A),
        onPressed: () => _showAdd(context, ep),
        child: const Icon(Icons.receipt_long, color: Colors.cyanAccent)),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _header(BuildContext ctx, ExpenseProvider ep) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(children: [
      // زر تقرير
      _circleBtn(Icons.bar_chart, onTap: () => _showReport(ctx, ep)),
      const Spacer(),
      Column(children: [
        const Text('المصروفات',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: Colors.cyan.shade700, borderRadius: BorderRadius.circular(20)),
          child: Text('الإجمالي: ${ep.totalAmount.toStringAsFixed(0)} ر.ي',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
      ]),
      const Spacer(),
      // زر تحديث
      _circleBtn(Icons.refresh, onTap: () => ep.loadAll()),
    ]),
  );

  // ── شريط الفلاتر وإدارة التصنيفات ───────────────────────
  Widget _filterRow(BuildContext ctx, ExpenseProvider ep) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(children: [
      // زر إدارة التصنيفات
      GestureDetector(
        onTap: () async {
          await Navigator.push(ctx,
              MaterialPageRoute(builder: (_) => const ExpenseCategoriesScreen()));
          // إعادة تحميل التصنيفات بعد العودة
          ep.loadAll();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.cyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.cyan.withOpacity(0.3)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.category_outlined, color: Colors.cyan, size: 16),
            SizedBox(width: 6),
            Text('التصنيفات', style: TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
      const Spacer(),
      // زر تصفية
      _circleBtn(Icons.tune, onTap: () => _showFilter(ctx, ep)),
    ]),
  );

  // ── بطاقة مصروف ─────────────────────────────────────────
  Widget _card(BuildContext ctx, ExpenseModel e, ExpenseProvider ep) {
    final color = ExpenseModel.categoryColors[e.category] ?? Colors.grey;
    return Dismissible(
      key: Key('exp_${e.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.redAccent)),
      onDismissed: (_) => ep.deleteExpense(e.id!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => ep.deleteExpense(e.id!)),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${e.amount.toStringAsFixed(0)} ر.ي',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('النوع: ${e.category}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(e.createdAt.substring(0, 10),
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
            if (e.notes != null && e.notes!.isNotEmpty)
              Text('ملاحظة: ${e.notes}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            radius: 24,
            child: Icon(ExpenseModel.categoryIcons[e.category] ?? Icons.money_off, color: color)),
        ]),
      ),
    );
  }

  Widget _empty() => const Expanded(child: Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.money_off, color: Colors.white24, size: 80),
      SizedBox(height: 12),
      Text('لا توجد مصروفات',
          style: TextStyle(color: Colors.white24, fontSize: 18, fontWeight: FontWeight.bold)),
      Text('اضغط + لإضافة مصروف',
          style: TextStyle(color: Colors.white24, fontSize: 13)),
    ])));

  Widget _circleBtn(IconData icon, {VoidCallback? onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(color: Color(0xFF1A1A24), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white70, size: 20)));

  void _showAdd(BuildContext ctx, ExpenseProvider ep) => showModalBottomSheet(
    context: ctx, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (_) => _AddExpenseSheet(
        ep: ep, onSave: () => ctx.read<HomeProvider>().refresh()));

  void _showFilter(BuildContext ctx, ExpenseProvider ep) => showModalBottomSheet(
    context: ctx, backgroundColor: const Color(0xFF1A1A24),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _FilterSheet(ep: ep));

  void _showReport(BuildContext ctx, ExpenseProvider ep) => showModalBottomSheet(
    context: ctx, backgroundColor: const Color(0xFF1A1A24), isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _ReportSheet(ep: ep));
}

// ══════════════════════════════════════════════════════════
// إضافة مصروف — مع تصنيفات ديناميكية
// ══════════════════════════════════════════════════════════
class _AddExpenseSheet extends StatefulWidget {
  final ExpenseProvider ep;
  final VoidCallback? onSave;
  const _AddExpenseSheet({required this.ep, this.onSave});
  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();
  String? _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // اختيار أول تصنيف متاح
    final cats = widget.ep.categories;
    _category = cats.isNotEmpty ? cats.first : 'أخرى';
  }

  @override
  Widget build(BuildContext ctx) {
    final cats = widget.ep.categories;
    // التأكد من أن _category موجود في القائمة
    if (!cats.contains(_category)) _category = cats.isNotEmpty ? cats.first : 'أخرى';

    return Container(
      decoration: const BoxDecoration(
          color: Color(0xFF1E1E2A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        // Handle
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Center(child: Text('إضافة مصروف',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(height: 20),

        // حقل المبلغ
        _field(_amountCtrl, 'المبلغ', Icons.attach_money, type: TextInputType.number),
        const SizedBox(height: 12),

        // قائمة التصنيفات الديناميكية
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: const Color(0xFF111116), borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A24),
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _category = v),
              items: cats.map((c) => DropdownMenuItem(
                value: c,
                child: Align(alignment: Alignment.centerRight, child: Text(c)))).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ملاحظات
        _field(_notesCtrl, 'ملاحظات (اختياري)', Icons.assignment),
        const SizedBox(height: 20),

        // أزرار
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)))),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: ElevatedButton(
            onPressed: _saving ? null : () async {
              final amt = double.tryParse(_amountCtrl.text);
              if (amt == null || amt <= 0) return;
              setState(() => _saving = true);
              final ok = await widget.ep.addExpense(
                  amt, _category ?? 'أخرى',
                  notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text);
              widget.onSave?.call();
              if (mounted) Navigator.pop(ctx);
              if (mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(ok ? '✅ تمت الإضافة' : '❌ فشل',
                    textDirection: TextDirection.rtl),
                backgroundColor: ok ? Colors.green : Colors.red));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('حفظ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
        ]),
      ]),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
          {TextInputType? type}) =>
      TextField(
        controller: c,
        textAlign: TextAlign.right,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          suffixIcon: Icon(icon, color: Colors.white30, size: 18),
          filled: true,
          fillColor: const Color(0xFF111116),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
}

// ══════════════════════════════════════════════════════════
// فلتر المصروفات — ديناميكي
// ══════════════════════════════════════════════════════════
class _FilterSheet extends StatefulWidget {
  final ExpenseProvider ep;
  const _FilterSheet({required this.ep});
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String _cat = 'الكل';

  @override
  Widget build(BuildContext context) {
    final cats = ['الكل', ...widget.ep.categories];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Center(child: Text('تصفية المصروفات',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(height: 20),
        const Text('حسب التصنيف', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: cats.map((c) => GestureDetector(
            onTap: () => setState(() => _cat = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _cat == c ? Colors.cyan.shade600 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _cat == c ? Colors.cyan.shade600 : Colors.white24)),
              child: Text(c, style: TextStyle(
                  color: Colors.white,
                  fontWeight: _cat == c ? FontWeight.bold : FontWeight.normal))),
          )).toList()),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            widget.ep.filter(category: _cat);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('تطبيق', style: TextStyle(color: Colors.white, fontSize: 16)))),
      ]));
  }
}

// ══════════════════════════════════════════════════════════
// تقرير المصروفات
// ══════════════════════════════════════════════════════════
class _ReportSheet extends StatelessWidget {
  final ExpenseProvider ep;
  const _ReportSheet({required this.ep});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.of(context).size.height * 0.85,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(children: [
          IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          const Spacer(),
          const Text('تقرير المصروفات',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        Container(
          color: const Color(0xFF162529),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: const Row(children: [
            Expanded(child: Center(child: Text('الوقت', style: TextStyle(color: Colors.cyan, fontSize: 11)))),
            Expanded(child: Center(child: Text('التاريخ', style: TextStyle(color: Colors.cyan, fontSize: 11)))),
            Expanded(child: Center(child: Text('المبلغ', style: TextStyle(color: Colors.cyan, fontSize: 11)))),
            Expanded(child: Center(child: Text('النوع', style: TextStyle(color: Colors.cyan, fontSize: 11)))),
          ])),
        Expanded(child: ListView.builder(
          itemCount: ep.expenses.length,
          itemBuilder: (_, i) {
            final e = ep.expenses[i];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10))),
              child: Row(children: [
                Expanded(child: Center(child: Text(
                    e.createdAt.length > 18 ? e.createdAt.substring(11, 16) : '-',
                    style: const TextStyle(color: Colors.white, fontSize: 11)))),
                Expanded(child: Center(child: Text(
                    e.createdAt.substring(0, 10),
                    style: const TextStyle(color: Colors.white, fontSize: 11)))),
                Expanded(child: Center(child: Text(
                    '${e.amount.toStringAsFixed(0)} ر.ي',
                    style: const TextStyle(color: Colors.white, fontSize: 11)))),
                Expanded(child: Center(child: Text(
                    e.category,
                    style: const TextStyle(color: Colors.white, fontSize: 11)))),
              ]));
          })),
        const Divider(color: Colors.white10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
              'الإجمالي: ${ep.totalAmount.toStringAsFixed(0)} ر.ي',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
      ])));
}
