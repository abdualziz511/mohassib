import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:mohassib/core/database/database_helper.dart';

class CashDrawerScreen extends StatefulWidget {
  const CashDrawerScreen({super.key});

  @override
  State<CashDrawerScreen> createState() => _CashDrawerScreenState();
}

class _CashDrawerScreenState extends State<CashDrawerScreen> {
  Map<String, dynamic>? _activeSession;
  bool _isLoading = true;
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // مبالغ الجلسة الحالية
  double _sessionSales = 0;
  double _sessionExpenses = 0;
  double _sessionReturns = 0;
  double _expectedBalance = 0;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    setState(() => _isLoading = true);
    final session = await DatabaseHelper.instance.getActiveCashSession();
    if (session != null) {
      _activeSession = session;
      await _loadSessionStats(session['opened_at']);
    } else {
      _activeSession = null;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadSessionStats(String openedAt) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN reference_type = 'sale' THEN amount ELSE 0 END) as sales,
        SUM(CASE WHEN reference_type = 'expense' THEN amount ELSE 0 END) as expenses,
        SUM(CASE WHEN reference_type = 'return' THEN amount ELSE 0 END) as returns
      FROM cash_transactions 
      WHERE created_at >= ?
    ''', [openedAt]);

    _sessionSales = (result.first['sales'] as num?)?.toDouble() ?? 0.0;
    _sessionExpenses = (result.first['expenses'] as num?)?.toDouble() ?? 0.0;
    _sessionReturns = (result.first['returns'] as num?)?.toDouble() ?? 0.0;
    
    final openBalance = _activeSession!['opening_balance'] as double;
    _expectedBalance = openBalance + _sessionSales - _sessionExpenses - _sessionReturns;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      appBar: AppBar(
        title: const Text('صندوق اليومية', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
        : _activeSession == null ? _buildOpenSessionUI() : _buildActiveSessionUI(),
    );
  }

  // ── واجهة فتح الصندوق ──────────────────────────────────────────
  Widget _buildOpenSessionUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const Center(child: Icon(Icons.lock_open_rounded, size: 80, color: Colors.cyan)),
        const SizedBox(height: 16),
        const Center(child: Text('الصندوق مغلق حالياً', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
        const Center(child: Text('يرجى إدخال المبلغ الافتتاحي لبدء الجلسة', style: TextStyle(color: Colors.grey, fontSize: 14))),
        const SizedBox(height: 32),
        _label('المبلغ الافتتاحي (النقد المتوفر في الدرج)'),
        _field(_amountCtrl, '0.0', Icons.payments_outlined, type: TextInputType.number),
        const SizedBox(height: 20),
        _label('ملاحظات (اختياري)'),
        _field(_notesCtrl, 'أضف ملاحظة...', Icons.notes),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _openSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('فتح الصندوق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ),
      ]),
    );
  }

  // ── واجهة الصندوق النشط ─────────────────────────────────────────
  Widget _buildActiveSessionUI() {
    final fmt = NumberFormat('#,##0', 'ar');
    final openedAt = DateTime.parse(_activeSession!['opened_at']);
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _infoCard('الصندوق نشط منذ: ${DateFormat('hh:mm a | dd/MM').format(openedAt)}'),
        const SizedBox(height: 20),
        
        _statTile('الرصيد الافتتاحي', fmt.format(_activeSession!['opening_balance']), Colors.grey),
        _statTile('إجمالي المبيعات (نقد)', fmt.format(_sessionSales), Colors.greenAccent),
        _statTile('إجمالي المصروفات', fmt.format(_sessionExpenses), Colors.redAccent),
        _statTile('إجمالي المرتجعات', fmt.format(_sessionReturns), Colors.orangeAccent),
        const Divider(color: Colors.white10, height: 40),
        _statTile('الرصيد المتوقع (في الدرج)', fmt.format(_expectedBalance), Colors.cyan, isBold: true),
        
        const SizedBox(height: 40),
        const Text('إغلاق الصندوق ومطابقة النقد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right),
        const SizedBox(height: 12),
        _label('المبلغ الفعلي الموجود في الدرج حالياً'),
        _field(_amountCtrl, 'أدخل المبلغ الفعلي...', Icons.account_balance_wallet_outlined, type: TextInputType.number),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _closeSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('إغلاق الصندوق وترحيل الجلسة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, Color color, {bool isBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Text('$value ر.ي', style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 15)),
      const Spacer(),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
    ]),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, right: 4),
    child: Text(t, style: const TextStyle(color: Colors.grey, fontSize: 13)));

  Widget _field(TextEditingController c, String hint, IconData icon, {TextInputType? type}) => Container(
    decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(12)),
    child: TextField(
      controller: c,
      textAlign: TextAlign.right,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        suffixIcon: Icon(icon, color: Colors.cyan, size: 20),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );

  Widget _infoCard(String t) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.cyan.withOpacity(0.1))),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(t, style: const TextStyle(color: Colors.cyan, fontSize: 13)),
      const SizedBox(width: 8),
      const Icon(Icons.info_outline, color: Colors.cyan, size: 16),
    ]),
  );

  Future<void> _openSession() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    await DatabaseHelper.instance.openCashSession(amount, _notesCtrl.text);
    _amountCtrl.clear();
    _notesCtrl.clear();
    _checkSession();
  }

  Future<void> _closeSession() async {
    if (_amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال المبلغ الفعلي للمطابقة')));
      return;
    }
    final actual = double.tryParse(_amountCtrl.text) ?? 0;
    
    // حساب الفرق قبل الإغلاق للعرض
    final diff = actual - _expectedBalance;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        title: const Text('تأكيد إغلاق الصندوق', style: TextStyle(color: Colors.white), textDirection: TextDirection.rtl),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('الرصيد المتوقع: ${NumberFormat('#,##0').format(_expectedBalance)} ر.ي', style: const TextStyle(color: Colors.grey)),
          Text('الرصيد الفعلي: ${NumberFormat('#,##0').format(actual)} ر.ي', style: const TextStyle(color: Colors.white)),
          const Divider(color: Colors.white10),
          Text(
            diff == 0 ? 'لا يوجد عجز أو فائض' : (diff > 0 ? 'يوجد فائض: ${diff.abs()} ر.ي' : 'يوجد عجز: ${diff.abs()} ر.ي'),
            style: TextStyle(color: diff >= 0 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.closeCashSession(
                sessionId: _activeSession!['id'],
                actualCash: actual,
              );
              _amountCtrl.clear();
              _checkSession();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم إغلاق الصندوق بنجاح'), backgroundColor: Colors.green));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('تأكيد الإغلاق', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
