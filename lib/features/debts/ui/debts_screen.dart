import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mohassib/features/debts/models/debt_model.dart';
import 'package:mohassib/features/home/home_provider.dart';
import 'package:mohassib/features/debts/ui/person_statement_screen.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});
  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  bool _showReceivable = false; // false=الالتزامات, true=الديون(لي)

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DebtProvider>();
    final list = _showReceivable ? dp.receivable : dp.payable;
    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      body: SafeArea(child: Stack(children: [
        Column(children: [
          _header(dp),
          _toggle(),
          _search(dp),
          const SizedBox(height: 8),
          dp.isLoading
            ? const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.cyan)))
            : list.isEmpty
              ? _empty()
              : Expanded(child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _card(context, list[i], dp),
                )),
        ]),
        _fab(context, dp),
      ])),
    );
  }

  Widget _header(DebtProvider dp) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.bar_chart, color: Colors.white70)),
      Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('الديون', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(children: [
            _badge('لي: ${dp.totalReceivable.toStringAsFixed(0)} ر.ي', Colors.greenAccent, Colors.black),
            const SizedBox(width: 8),
            _badge('علي: ${dp.totalPayable.toStringAsFixed(0)} ر.ي', Colors.redAccent, Colors.white),
          ]),
        ]),
        const SizedBox(width: 12),
        InkWell(onTap: () => context.read<DebtProvider>().loadAll(),
          child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF1A1A24), shape: BoxShape.circle),
            child: const Icon(Icons.refresh, color: Colors.white70))),
      ]),
    ]),
  );

  Widget _badge(String t, Color bg, Color text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Text(t, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11)));

  Widget _toggle() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(children: [
      Expanded(child: GestureDetector(
        onTap: () => setState(() => _showReceivable = true),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: _showReceivable ? Colors.greenAccent : const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text('الديون (لي)', style: TextStyle(color: _showReceivable ? Colors.black : Colors.white, fontWeight: FontWeight.bold)))))),
      const SizedBox(width: 8),
      Expanded(child: GestureDetector(
        onTap: () => setState(() => _showReceivable = false),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: !_showReceivable ? Colors.redAccent : const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text('الالتزامات (علي)', style: TextStyle(color: !_showReceivable ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)))))),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: d.statusColor.withOpacity(0.3))),
      child: Column(children: [
        Row(children: [
          Row(children: [
            IconButton(onPressed: () => _confirmDelete(ctx, d, dp), icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), constraints: const BoxConstraints()),
            const SizedBox(width: 4),
            if (!d.isPaid) IconButton(onPressed: () => _showPayDialog(ctx, d, dp), icon: const Icon(Icons.payments_outlined, color: Colors.greenAccent, size: 20), constraints: const BoxConstraints()),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => PersonStatementScreen(personName: d.personName, type: d.type))), 
              icon: const Icon(Icons.receipt_long, color: Colors.blueAccent, size: 20), 
              constraints: const BoxConstraints()
            ),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(d.personName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            if (d.phone != null) Text(d.phone!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
          const SizedBox(width: 12),
          CircleAvatar(backgroundColor: d.statusColor.withOpacity(0.1), radius: 22,
            child: Icon(d.isReceivable ? Icons.arrow_downward : Icons.arrow_upward, color: d.statusColor)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: d.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: d.statusColor.withOpacity(0.3))),
            child: Text(d.statusLabel, style: TextStyle(color: d.statusColor, fontWeight: FontWeight.bold, fontSize: 11))),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${d.amount.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            if (d.paidAmount > 0) Text('مسدد: ${d.paidAmount.toStringAsFixed(0)} | متبقي: ${d.remaining.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ]),
        if (d.notes != null && d.notes!.isNotEmpty) ...[
          const Divider(color: Colors.white10, height: 16),
          Align(alignment: Alignment.centerRight, child: Text(d.notes!, style: const TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ]),
    );
  }

  Widget _empty() => Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.handshake_outlined, color: Colors.white24, size: 80),
    const SizedBox(height: 12),
    Text(_showReceivable ? 'لا توجد ديون' : 'لا توجد التزامات', style: const TextStyle(color: Colors.white24, fontSize: 18, fontWeight: FontWeight.bold)),
    const Text('اضغط + لإضافة', style: TextStyle(color: Colors.white24, fontSize: 13)),
  ])));

  Widget _fab(BuildContext ctx, DebtProvider dp) => Positioned(
    bottom: 16, right: 16,
    child: FloatingActionButton(
      backgroundColor: const Color(0xFF1E1E2A),
      onPressed: () => _showAdd(ctx, dp),
      child: const Icon(Icons.person_add_alt_1, color: Colors.cyan)));

  void _showAdd(BuildContext ctx, DebtProvider dp) => showModalBottomSheet(
    context: ctx, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (_) => _AddDebtSheet(dp: dp, defaultType: _showReceivable ? 'receivable' : 'payable',
      onSave: () => ctx.read<HomeProvider>().refresh()));

  void _confirmDelete(BuildContext ctx, DebtModel d, DebtProvider dp) => showDialog(context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E2A),
      title: const Text('حذف الدين', style: TextStyle(color: Colors.white), textDirection: TextDirection.rtl),
      content: Text('هل تريد حذف دين "${d.personName}"؟', style: const TextStyle(color: Colors.grey), textDirection: TextDirection.rtl),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        TextButton(onPressed: () { dp.deleteDebt(d.id!); Navigator.pop(ctx); }, child: const Text('حذف', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
      ]));

  void _showPayDialog(BuildContext ctx, DebtModel d, DebtProvider dp) {
    final ctrl = TextEditingController(text: d.remaining.toStringAsFixed(0));
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E2A),
      title: Text('تسجيل سداد - ${d.personName}', style: const TextStyle(color: Colors.white), textDirection: TextDirection.rtl),
      content: TextField(controller: ctrl, textAlign: TextAlign.right, keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(hintText: 'المبلغ المسدد', hintStyle: const TextStyle(color: Colors.grey),
          filled: true, fillColor: const Color(0xFF111116), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
        TextButton(onPressed: () async {
          final amt = double.tryParse(ctrl.text) ?? 0;
          if (amt > 0) { await dp.addPayment(d.id!, amt); ctx.read<HomeProvider>().refresh(); }
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('تأكيد', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
      ]));
  }
}

// ── Add Debt Sheet ─────────────────────────────────────────────
class _AddDebtSheet extends StatefulWidget {
  final DebtProvider dp;
  final String defaultType;
  final VoidCallback? onSave;
  const _AddDebtSheet({required this.dp, required this.defaultType, this.onSave});
  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}
class _AddDebtSheetState extends State<_AddDebtSheet> {
  late String _type;
  final _name   = TextEditingController();
  final _phone  = TextEditingController();
  final _amount = TextEditingController();
  final _notes  = TextEditingController();
  bool _whatsapp = false;
  bool _saving = false;
  @override
  void initState() { super.initState(); _type = widget.defaultType; }
  @override
  Widget build(BuildContext ctx) => Container(
    decoration: const BoxDecoration(color: Color(0xFF1E1E2A), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 16),
      const Center(child: Text('إضافة دين', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: GestureDetector(onTap: () => setState(() => _type = 'payable'),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: _type == 'payable' ? Colors.redAccent : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: _type == 'payable' ? Colors.redAccent : Colors.white24)),
            child: const Center(child: Text('علي (التزام)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))))),
        const SizedBox(width: 8),
        Expanded(child: GestureDetector(onTap: () => setState(() => _type = 'receivable'),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: _type == 'receivable' ? Colors.greenAccent : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: _type == 'receivable' ? Colors.greenAccent : Colors.white24)),
            child: Center(child: Text('لي (دين)', style: TextStyle(color: _type == 'receivable' ? Colors.black : Colors.white, fontWeight: FontWeight.bold)))))),
      ]),
      const SizedBox(height: 12),
      _field(_name,   'اسم الشخص / الجهة', Icons.person),
      const SizedBox(height: 8),
      _field(_phone,  'رقم الهاتف', Icons.phone, type: TextInputType.phone),
      const SizedBox(height: 8),
      _field(_amount, 'المبلغ', Icons.attach_money, type: TextInputType.number),
      const SizedBox(height: 8),
      _field(_notes,  'ملاحظات', Icons.assignment),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Switch(value: _whatsapp, onChanged: (v) => setState(() => _whatsapp = v), activeColor: Colors.green),
        const Row(children: [Text('تنبيه واتساب', style: TextStyle(color: Colors.white70)), SizedBox(width: 6), Icon(Icons.chat, color: Colors.green, size: 20)]),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('إلغاء', style: TextStyle(color: Colors.white70)))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: ElevatedButton(
          onPressed: _saving ? null : () async {
            if (_name.text.isEmpty || _amount.text.isEmpty) return;
            setState(() => _saving = true);
            final ok = await widget.dp.addDebt(type: _type, personName: _name.text, phone: _phone.text.isEmpty ? null : _phone.text,
              amount: double.tryParse(_amount.text) ?? 0, notes: _notes.text.isEmpty ? null : _notes.text, whatsappAlert: _whatsapp);
            widget.onSave?.call();
            if (mounted) Navigator.pop(ctx);
            if (mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(ok ? '✅ تمت الإضافة' : '❌ فشل', textDirection: TextDirection.rtl), backgroundColor: ok ? Colors.green : Colors.red));
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      ]),
    ])));

  Widget _field(TextEditingController c, String hint, IconData icon, {TextInputType? type}) => TextField(
    controller: c, textAlign: TextAlign.right, keyboardType: type, style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.grey), suffixIcon: Icon(icon, color: Colors.white30, size: 18),
      filled: true, fillColor: const Color(0xFF111116), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
}
