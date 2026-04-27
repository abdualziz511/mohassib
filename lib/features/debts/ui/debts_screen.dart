import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mohassib/features/debts/models/debt_model.dart';
import 'package:mohassib/features/home/home_provider.dart';
import 'package:mohassib/features/debts/ui/person_statement_screen.dart';
import 'package:mohassib/features/customers/models/customer_model.dart';
import 'package:mohassib/features/suppliers/models/supplier_model.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});
  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  bool _showReceivable = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DebtProvider>().loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DebtProvider>();
    final list = _showReceivable ? dp.receivable : dp.payable;

    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      body: SafeArea(child: Column(children: [
        _header(dp),
        _toggle(),
        _search(dp),
        const SizedBox(height: 4),
        dp.isLoading
            ? const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.cyan)))
            : list.isEmpty
                ? _empty()
                : Expanded(child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _card(context, list[i], dp),
                  )),
      ])),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.cyan,
        onPressed: () => _showAddDebt(context, dp),
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
    );
  }

  Widget _header(DebtProvider dp) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      InkWell(
        onTap: () => dp.loadAll(),
        child: Container(padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Color(0xFF1A1A24), shape: BoxShape.circle),
          child: const Icon(Icons.refresh, color: Colors.white70)),
      ),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const Text('الديون', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(children: [
          _badge('علي: ${dp.totalPayable.toStringAsFixed(0)} ر.ي', Colors.redAccent, Colors.white),
          const SizedBox(width: 8),
          _badge('لي: ${dp.totalReceivable.toStringAsFixed(0)} ر.ي', Colors.greenAccent, Colors.black),
        ]),
      ]),
    ]),
  );

  Widget _badge(String t, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Text(t, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11)));

  Widget _toggle() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(children: [
      Expanded(child: GestureDetector(
        onTap: () => setState(() => _showReceivable = false),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: !_showReceivable ? Colors.redAccent : const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text('الالتزامات (علي)',
            style: TextStyle(color: !_showReceivable ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)))))),
      const SizedBox(width: 8),
      Expanded(child: GestureDetector(
        onTap: () => setState(() => _showReceivable = true),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _showReceivable ? Colors.greenAccent : const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text('الديون (لي)',
            style: TextStyle(color: _showReceivable ? Colors.black : Colors.white70, fontWeight: FontWeight.bold)))))),
    ]),
  );

  Widget _search(DebtProvider dp) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: TextField(
      textAlign: TextAlign.right,
      style: const TextStyle(color: Colors.white),
      onChanged: dp.search,
      decoration: InputDecoration(
        hintText: 'بحث عن شخص...',
        hintStyle: const TextStyle(color: Colors.grey),
        suffixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true, fillColor: const Color(0xFF1A1A24),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))));

  Widget _card(BuildContext ctx, DebtModel d, DebtProvider dp) {
    return GestureDetector(
      onTap: () => Navigator.push(ctx, MaterialPageRoute(
        builder: (_) => PersonStatementScreen(personName: d.personName, type: d.type))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: d.statusColor.withOpacity(0.3))),
        child: Column(children: [
          Row(children: [
            Row(children: [
              IconButton(
                onPressed: () => _confirmDelete(ctx, d, dp),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                constraints: const BoxConstraints(), padding: EdgeInsets.zero),
              const SizedBox(width: 8),
              if (!d.isPaid) IconButton(
                onPressed: () => _showPayDialog(ctx, d, dp),
                icon: const Icon(Icons.payments_outlined, color: Colors.greenAccent, size: 20),
                constraints: const BoxConstraints(), padding: EdgeInsets.zero),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.push(ctx, MaterialPageRoute(
                  builder: (_) => PersonStatementScreen(personName: d.personName, type: d.type))),
                icon: const Icon(Icons.receipt_long, color: Colors.blueAccent, size: 20),
                constraints: const BoxConstraints(), padding: EdgeInsets.zero),
            ]),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(d.personName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(width: 8),
                if (d.isLinked)
                  const Icon(Icons.link, color: Colors.cyanAccent, size: 14),
              ]),
              if (d.phone != null && d.phone!.isNotEmpty)
                Text(d.phone!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: d.statusColor.withOpacity(0.15), radius: 22,
              child: Icon(d.isReceivable ? Icons.arrow_downward : Icons.arrow_upward,
                color: d.statusColor)),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: d.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: d.statusColor.withOpacity(0.3))),
              child: Text(d.statusLabel,
                style: TextStyle(color: d.statusColor, fontWeight: FontWeight.bold, fontSize: 11))),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${d.amount.toStringAsFixed(0)} ر.ي',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              if (d.paidAmount > 0)
                Text(
                  'مسدد: ${d.paidAmount.toStringAsFixed(0)} | متبقي: ${d.remaining.toStringAsFixed(0)} ر.ي',
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
          ]),
          if (d.notes != null && d.notes!.isNotEmpty) ...[
            const Divider(color: Colors.white10, height: 16),
            Align(alignment: Alignment.centerRight,
              child: Text(d.notes!, style: const TextStyle(color: Colors.grey, fontSize: 12))),
          ],
        ]),
      ),
    );
  }

  Widget _empty() => Expanded(child: Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.handshake_outlined, color: Colors.white24, size: 80),
      const SizedBox(height: 12),
      Text(_showReceivable ? 'لا توجد ديون' : 'لا توجد التزامات',
        style: const TextStyle(color: Colors.white24, fontSize: 18, fontWeight: FontWeight.bold)),
      const Text('اضغط + لإضافة', style: TextStyle(color: Colors.white24, fontSize: 13)),
    ])));

  void _showAddDebt(BuildContext ctx, DebtProvider dp) => showModalBottomSheet(
    context: ctx,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _AddDebtSheet(
      dp: dp,
      defaultType: _showReceivable ? 'receivable' : 'payable',
      onSaved: () => ctx.read<HomeProvider>().refresh(),
    ),
  );

  void _confirmDelete(BuildContext ctx, DebtModel d, DebtProvider dp) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E2A),
      title: const Text('حذف الدين', style: TextStyle(color: Colors.white), textDirection: TextDirection.rtl),
      content: Text(
        'سيتم حذف دين "${d.personName}" (${d.remaining.toStringAsFixed(0)} ر.ي متبقي) وتصحيح رصيد الحساب تلقائياً.',
        style: const TextStyle(color: Colors.grey), textDirection: TextDirection.rtl),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        TextButton(
          onPressed: () { dp.deleteDebt(d); Navigator.pop(ctx); },
          child: const Text('حذف', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
      ]));

  void _showPayDialog(BuildContext ctx, DebtModel d, DebtProvider dp) {
    final ctrl = TextEditingController(text: d.remaining.toStringAsFixed(0));
    final notesCtrl = TextEditingController(text: 'سداد دفعة');
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E2A),
      title: Text('سداد - ${d.personName}',
        style: const TextStyle(color: Colors.white), textDirection: TextDirection.rtl),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('المتبقي: ${d.remaining.toStringAsFixed(0)} ر.ي',
          style: const TextStyle(color: Colors.orangeAccent, fontSize: 13)),
        const SizedBox(height: 12),
        _darkField(ctrl, 'المبلغ المسدد', TextInputType.number),
        const SizedBox(height: 8),
        _darkField(notesCtrl, 'البيان', TextInputType.text),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        TextButton(
          onPressed: () async {
            final amt = double.tryParse(ctrl.text) ?? 0;
            if (amt > 0 && amt <= d.remaining) {
              await dp.addPayment(d.id!, amt, notes: notesCtrl.text.isEmpty ? null : notesCtrl.text);
              if (ctx.mounted) {
                ctx.read<HomeProvider>().refresh();
                Navigator.pop(ctx);
              }
            }
          },
          child: const Text('تأكيد السداد', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
      ]));
  }

  Widget _darkField(TextEditingController c, String hint, TextInputType type) => TextField(
    controller: c, textAlign: TextAlign.right, keyboardType: type,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.grey),
      filled: true, fillColor: const Color(0xFF111116),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)));
}

// ══════════════════════════════════════════════════════════════
// شاشة إضافة دين — مع بحث ذكي واقتراح العملاء/الموردين
// ══════════════════════════════════════════════════════════════
class _AddDebtSheet extends StatefulWidget {
  final DebtProvider dp;
  final String defaultType;
  final VoidCallback? onSaved;
  const _AddDebtSheet({required this.dp, required this.defaultType, this.onSaved});
  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<_AddDebtSheet> {
  late String _type;
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();

  CustomerModel? _selectedCustomer;
  SupplierModel? _selectedSupplier;
  List<dynamic> _suggestions = [];
  bool _saving = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType;
    _nameCtrl.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final q = _nameCtrl.text;
    _selectedCustomer = null;
    _selectedSupplier = null;
    if (q.isEmpty) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    final dp = widget.dp;
    final results = _type == 'receivable'
        ? dp.searchCustomers(q)
        : dp.searchSuppliers(q);
    setState(() {
      _suggestions = results;
      _showSuggestions = results.isNotEmpty;
    });
  }

  void _selectSuggestion(dynamic person) {
    if (person is CustomerModel) {
      _selectedCustomer = person;
      _nameCtrl.text = person.name;
      _phoneCtrl.text = person.phone ?? '';
    } else if (person is SupplierModel) {
      _selectedSupplier = person;
      _nameCtrl.text = person.name;
      _phoneCtrl.text = person.phone ?? '';
    }
    setState(() { _suggestions = []; _showSuggestions = false; });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _amountCtrl.text.trim().isEmpty) return;
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);

    // هل الشخص موجود سلفاً أم جديد؟
    final bool isNew = _selectedCustomer == null && _selectedSupplier == null;

    final ok = await widget.dp.addDebtWithCustomer(
      type: _type,
      personName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      amount: amount,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      existingCustomerId: _selectedCustomer?.id,
      existingSupplierId: _selectedSupplier?.id,
      createNewPerson: isNew,
    );

    widget.onSaved?.call();
    if (mounted) Navigator.pop(context);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
          ? isNew
            ? '✅ تمت الإضافة وتم إنشاء ${_type == "receivable" ? "عميل" : "مورد"} جديد'
            : '✅ تمت الإضافة على حساب ${_nameCtrl.text}'
          : '❌ فشل الحفظ',
          textDirection: TextDirection.rtl),
        backgroundColor: ok ? Colors.green : Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end, children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Center(child: Text('إضافة دين', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(height: 16),

        // نوع الدين
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () { setState(() { _type = 'payable'; _onNameChanged(); }); },
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _type == 'payable' ? Colors.redAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _type == 'payable' ? Colors.redAccent : Colors.white24)),
              child: const Center(child: Text('علي (التزام)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))))),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(
            onTap: () { setState(() { _type = 'receivable'; _onNameChanged(); }); },
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _type == 'receivable' ? Colors.greenAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _type == 'receivable' ? Colors.greenAccent : Colors.white24)),
              child: Center(child: Text('لي (دين)',
                style: TextStyle(color: _type == 'receivable' ? Colors.black : Colors.white, fontWeight: FontWeight.bold)))))),
        ]),
        const SizedBox(height: 12),

        // حقل الاسم مع الاقتراحات
        _field(_nameCtrl, _type == 'receivable' ? 'اسم العميل / الشخص' : 'اسم المورد / الشخص', Icons.person),
        if (_showSuggestions) _suggestionsBox(),
        const SizedBox(height: 8),
        if (_selectedCustomer != null || _selectedSupplier != null)
          _linkedBadge(),
        _field(_phoneCtrl, 'رقم الهاتف (اختياري)', Icons.phone, type: TextInputType.phone),
        const SizedBox(height: 8),
        _field(_amountCtrl, 'المبلغ', Icons.attach_money, type: TextInputType.number),
        const SizedBox(height: 8),
        _field(_notesCtrl, 'ملاحظات (اختياري)', Icons.notes),
        const SizedBox(height: 16),

        // أزرار الحفظ / الإلغاء
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)))),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('حفظ الدين', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
        ]),
      ])),
    );
  }

  Widget _suggestionsBox() => Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF111116),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.cyan.withOpacity(0.3))),
    child: Column(mainAxisSize: MainAxisSize.min,
      children: _suggestions.map((p) {
        final name = p is CustomerModel ? p.name : (p as SupplierModel).name;
        final phone = p is CustomerModel ? p.phone : (p as SupplierModel).phone;
        final balance = p is CustomerModel ? p.currentBalance : (p as SupplierModel).currentBalance;
        return ListTile(
          dense: true,
          onTap: () => _selectSuggestion(p),
          leading: CircleAvatar(
            backgroundColor: Colors.cyan.withOpacity(0.2), radius: 16,
            child: Text(name[0], style: const TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold))),
          title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
          subtitle: phone != null ? Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 11)) : null,
          trailing: balance > 0
              ? Text('${balance.toStringAsFixed(0)} ر.ي',
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold))
              : null,
        );
      }).toList()),
  );

  Widget _linkedBadge() {
    final name = _selectedCustomer?.name ?? _selectedSupplier?.name ?? '';
    final label = _selectedCustomer != null ? 'عميل مسجل' : 'مورد مسجل';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.cyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan.withOpacity(0.4))),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text('سيُضاف على حساب $name ($label)',
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
        const SizedBox(width: 6),
        const Icon(Icons.link, color: Colors.cyan, size: 16),
      ]),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon, {TextInputType? type}) => TextField(
    controller: c, textAlign: TextAlign.right, keyboardType: type,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.grey),
      suffixIcon: Icon(icon, color: Colors.white30, size: 18),
      filled: true, fillColor: const Color(0xFF111116),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
}
