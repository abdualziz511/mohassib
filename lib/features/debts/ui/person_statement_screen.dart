import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/pdf_service.dart';
import '../../debts/models/debt_model.dart';
import '../../home/home_provider.dart';
import '../../customers/provider/customer_provider.dart';
import '../../suppliers/provider/supplier_provider.dart';

class PersonStatementScreen extends StatefulWidget {
  final String personName;
  final String type; // 'receivable' | 'payable'
  const PersonStatementScreen({super.key, required this.personName, required this.type});

  @override
  State<PersonStatementScreen> createState() => _PersonStatementScreenState();
}

class _PersonStatementScreenState extends State<PersonStatementScreen> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _statement = [];
  bool _isLoading = true;
  double _totalDebt = 0;
  double _totalPaid = 0;
  int? _linkedId; // customer_id أو supplier_id

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _db.getPersonStatement(widget.personName, widget.type);

    double td = 0, tp = 0;
    for (final r in data) {
      final amt = (r['amount'] as num).toDouble();
      if (r['record_type'] == 'debt') td += amt;
      else tp += amt;
    }

    // جلب الـ id المرتبط
    final dp = context.read<DebtProvider>();
    _linkedId = dp.getLinkedId(widget.personName, widget.type);

    setState(() {
      _statement = data;
      _totalDebt = td;
      _totalPaid = tp;
      _isLoading = false;
    });
  }

  double get _remaining => (_totalDebt - _totalPaid).clamp(0, double.infinity);
  bool get _isReceivable => widget.type == 'receivable';

  String _fmt(String iso) {
    try {
      return intl.DateFormat('dd/MM/yyyy hh:mm a', 'en').format(DateTime.parse(iso));
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A24),
        title: Text('كشف: ${widget.personName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'مشاركة PDF',
            onPressed: _statement.isEmpty ? null : () => _exportPdf(share: true),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'طباعة',
            onPressed: _statement.isEmpty ? null : () => _exportPdf(share: false),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : Column(children: [
              _summaryCard(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(alignment: Alignment.centerRight,
                  child: Text('سجل الحركات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
              _statement.isEmpty
                  ? const Expanded(child: Center(
                      child: Text('لا توجد حركات مسجلة', style: TextStyle(color: Colors.white38, fontSize: 16))))
                  : Expanded(child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _statement.length,
                      itemBuilder: (_, i) => _statementRow(_statement[i], i),
                    )),
            ]),
      floatingActionButton: _remaining > 0
          ? FloatingActionButton.extended(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.payments),
              label: const Text('سداد الدفتر', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _showPayAllDialog(),
            )
          : FloatingActionButton.extended(
              backgroundColor: Colors.green.shade800,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.check_circle),
              label: const Text('الحساب مسدّد بالكامل', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: null,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _summaryCard() {
    final color = _isReceivable ? Colors.teal : Colors.red;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.shade900, color.shade700],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(children: [
        Text(_isReceivable ? 'مدين لك' : 'دين عليك',
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Text('${_remaining.toStringAsFixed(0)} ر.ي',
          style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
        if (_remaining <= 0)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
            child: const Text('✅ الحساب مسدّد بالكامل',
              style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _summaryItem('إجمالي المسدد', _totalPaid, Icons.check_circle, Colors.greenAccent),
          Container(width: 1, height: 40, color: Colors.white24),
          _summaryItem('إجمالي الديون', _totalDebt, Icons.account_balance_wallet, Colors.orangeAccent),
        ]),
      ]),
    );
  }

  Widget _summaryItem(String label, double amt, IconData icon, Color color) => Row(children: [
    Icon(icon, color: color, size: 20),
    const SizedBox(width: 8),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      Text('${amt.toStringAsFixed(0)} ر.ي',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    ]),
  ]);

  Widget _statementRow(Map<String, dynamic> item, int index) {
    final isDebt = item['record_type'] == 'debt';
    final amount = (item['amount'] as num).toDouble();
    final notes = item['notes']?.toString() ?? '';

    Color color;
    IconData icon;
    String label;

    if (_isReceivable) {
      color = isDebt ? Colors.orangeAccent : Colors.greenAccent;
      icon  = isDebt ? Icons.shopping_bag_outlined : Icons.payments_outlined;
      label = isDebt ? 'بيع آجل (دين)' : 'سداد استُلم';
    } else {
      color = isDebt ? Colors.redAccent : Colors.greenAccent;
      icon  = isDebt ? Icons.inventory_2_outlined : Icons.payments_outlined;
      label = isDebt ? 'شراء آجل (دين عليك)' : 'دفعة سُدِّدت';
    }

    // حساب الرصيد المتراكم حتى هذا السطر
    double balance = 0;
    for (int i = 0; i <= index; i++) {
      final r = _statement[i];
      final a = (r['amount'] as num).toDouble();
      if (r['record_type'] == 'debt') balance += a;
      else balance -= a;
    }
    balance = balance.clamp(0, double.infinity);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25))),
      child: Row(children: [
        // رصيد متراكم
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('الرصيد', style: TextStyle(color: Colors.grey, fontSize: 9)),
          Text('${balance.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(width: 12),
        // المبلغ
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
          child: Text(
            '${isDebt ? "+" : "-"}${amount.toStringAsFixed(0)} ر.ي',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14))),
        const SizedBox(width: 12),
        // التفاصيل
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 8),
            CircleAvatar(backgroundColor: color.withOpacity(0.15), radius: 14,
              child: Icon(icon, color: color, size: 14)),
          ]),
          if (notes.isNotEmpty)
            Text(notes, style: const TextStyle(color: Colors.white54, fontSize: 11),
              textDirection: TextDirection.rtl),
          Text(_fmt(item['created_at']),
            style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ])),
      ]),
    );
  }

  void _showPayAllDialog() {
    final amtCtrl = TextEditingController(text: _remaining.toStringAsFixed(0));
    final notesCtrl = TextEditingController(
      text: _isReceivable ? 'استلام كامل الحساب' : 'سداد كامل الحساب');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        title: Text('سداد حساب: ${widget.personName}',
          style: const TextStyle(color: Colors.white), textDirection: TextDirection.rtl),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${_remaining.toStringAsFixed(0)} ر.ي',
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('الرصيد المتبقي:', style: TextStyle(color: Colors.white70)),
            ])),
          const SizedBox(height: 16),
          _payField(amtCtrl, 'المبلغ المدفوع', TextInputType.number),
          const SizedBox(height: 8),
          _payField(notesCtrl, 'البيان', TextInputType.text),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text) ?? 0;
              if (amt <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('المبلغ غير صحيح'),
                    backgroundColor: Colors.red));
                return;
              }

              Navigator.pop(ctx);

              final dp = context.read<DebtProvider>();
              final excess = await dp.payAllForPerson(
                personName: widget.personName,
                type: widget.type,
                amount: amt,
                notes: notesCtrl.text.trim().isEmpty ? 'سداد' : notesCtrl.text.trim(),
                customerId: _isReceivable ? _linkedId : null,
                supplierId: !_isReceivable ? _linkedId : null,
              );

              if (mounted) {
                context.read<HomeProvider>().refresh();
                context.read<CustomerProvider>().loadAll();
                context.read<SupplierProvider>().loadAll();
                _load(); // تحديث الكشف
                
                String msg = '✅ تم السداد وتحديث الرصيد';
                if (excess > 0) {
                  msg += '\nيوجد مبلغ زائد: ${excess.toStringAsFixed(0)} ر.ي لم يطبق على أي دين.';
                }
                
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(msg, textDirection: TextDirection.rtl),
                  backgroundColor: excess > 0 ? Colors.orange : Colors.green,
                  duration: const Duration(seconds: 4),
                ));
              }
            },
            child: const Text('سداد وتحديث الكشف',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
        ]));
  }

  Widget _payField(TextEditingController c, String hint, TextInputType type) => TextField(
    controller: c, keyboardType: type, textAlign: TextAlign.right,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.grey),
      filled: true, fillColor: const Color(0xFF111116),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)));

  Future<void> _exportPdf({required bool share}) async {
    final hp = context.read<HomeProvider>();
    await PdfService.generateStatementPdf(
      widget.personName, _totalDebt, _totalPaid,
      _totalDebt - _totalPaid, _statement,
      hp.storeName, hp.ownerName, share);
  }
}
