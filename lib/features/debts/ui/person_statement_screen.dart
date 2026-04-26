import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/database/database_helper.dart';
import '../../../core/utils/pdf_service.dart';
import 'package:provider/provider.dart';
import '../../customers/provider/customer_provider.dart';
import '../../suppliers/provider/supplier_provider.dart';
import '../../home/home_provider.dart';
import '../../debts/models/debt_model.dart';

class PersonStatementScreen extends StatefulWidget {
  final String personName;
  final String type; // 'receivable' or 'payable'

  const PersonStatementScreen({super.key, required this.personName, required this.type});

  @override
  State<PersonStatementScreen> createState() => _PersonStatementScreenState();
}

class _PersonStatementScreenState extends State<PersonStatementScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _statement = [];
  bool _isLoading = true;
  double _totalDebt = 0.0;
  double _totalPaid = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStatement();
  }

  Future<void> _loadStatement() async {
    final data = await _db.getPersonStatement(widget.personName, widget.type);
    
    double tDebt = 0;
    double tPaid = 0;
    
    for (var r in data) {
      final amt = (r['amount'] as num).toDouble();
      if (r['record_type'] == 'debt') {
        tDebt += amt;
      } else {
        tPaid += amt;
      }
    }

    setState(() {
      _statement = data;
      _totalDebt = tDebt;
      _totalPaid = tPaid;
      _isLoading = false;
    });
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return intl.DateFormat('yyyy/MM/dd hh:mm a', 'en').format(d);
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _totalDebt - _totalPaid;
    final isReceivable = widget.type == 'receivable';

    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A24),
        title: Text('كشف حساب: ${widget.personName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              if (_statement.isEmpty) return;
              final hp = context.read<HomeProvider>();
              PdfService.generateStatementPdf(widget.personName, _totalDebt, _totalPaid, _totalDebt - _totalPaid, _statement, hp.storeName, hp.ownerName, true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: () {
              if (_statement.isEmpty) return;
              final hp = context.read<HomeProvider>();
              PdfService.generateStatementPdf(widget.personName, _totalDebt, _totalPaid, _totalDebt - _totalPaid, _statement, hp.storeName, hp.ownerName, false);
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
        : Column(
            children: [
              // Summary Cards
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isReceivable 
                      ? [Colors.teal.shade900, Colors.teal.shade700]
                      : [Colors.red.shade900, Colors.red.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: (isReceivable ? Colors.teal : Colors.red).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                  ]
                ),
                child: Column(
                  children: [
                    const Text('الرصيد المتبقي (الإجمالي)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('${remaining.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _summaryItem('إجمالي الديون', _totalDebt, Icons.account_balance_wallet, Colors.orangeAccent),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _summaryItem('إجمالي المسدد', _totalPaid, Icons.check_circle, Colors.greenAccent),
                      ],
                    )
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('سجل العمليات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                ),
              ),

              Expanded(
                child: _statement.isEmpty
                  ? const Center(child: Text('لا توجد حركات مسجلة', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _statement.length,
                      itemBuilder: (ctx, i) {
                        final item = _statement[i];
                        final isDebt = item['record_type'] == 'debt';
                        final amount = (item['amount'] as num).toDouble();
                        
                        Color iconColor;
                        IconData iconData;
                        String title;
                        
                        if (isReceivable) {
                          iconColor = isDebt ? Colors.orangeAccent : Colors.greenAccent;
                          iconData = isDebt ? Icons.shopping_bag_outlined : Icons.payments_outlined;
                          title = isDebt ? 'أخذ بضاعة (دين)' : 'سداد دفعة لك';
                        } else {
                          iconColor = isDebt ? Colors.redAccent : Colors.greenAccent;
                          iconData = isDebt ? Icons.inventory_2_outlined : Icons.payments_outlined;
                          title = isDebt ? 'أخذت بضاعة (دين عليك)' : 'سداد دفعة للمورد';
                        }
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A24),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: iconColor.withOpacity(0.3))
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: iconColor.withOpacity(0.1),
                                child: Icon(iconData, color: iconColor, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(_formatDate(item['created_at']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(item['notes'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                      )
                                  ],
                                ),
                              ),
                              Text('${amount.toStringAsFixed(0)} ر.ي', style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
      floatingActionButton: remaining > 0 ? FloatingActionButton.extended(
        backgroundColor: Colors.cyan,
        icon: const Icon(Icons.payments, color: Colors.white),
        label: const Text('سداد الدفتر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showPayAllDialog(context, remaining, isReceivable),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showPayAllDialog(BuildContext context, double remaining, bool isReceivable) {
    final amtCtrl = TextEditingController(text: remaining.toStringAsFixed(0));
    final notesCtrl = TextEditingController(text: isReceivable ? 'سداد دفعة من الحساب' : 'سداد دفعة للمورد');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        title: Text('تسديد حساب: ${widget.personName}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الرصيد المتبقي: $remaining ر.ي', style: const TextStyle(color: Colors.orangeAccent)),
            const SizedBox(height: 16),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'المبلغ المدفوع', labelStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: const Color(0xFF111116), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'ملاحظات', labelStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: const Color(0xFF111116), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text);
              if (amt != null && amt > 0) {
                if (isReceivable) {
                  final cp = context.read<CustomerProvider>();
                  final cust = cp.customers.where((c) => c.name == widget.personName).toList();
                  if (cust.isNotEmpty && cust.first.id != null) {
                    await cp.payDebtBulk(cust.first.id!, amt, notesCtrl.text);
                  }
                } else {
                  final sp = context.read<SupplierProvider>();
                  final sup = sp.suppliers.where((s) => s.name == widget.personName).toList();
                  if (sup.isNotEmpty && sup.first.id != null) {
                    await sp.payDebtBulk(sup.first.id!, amt, notesCtrl.text);
                  }
                }
                if (ctx.mounted) {
                  context.read<HomeProvider>().refresh();
                  context.read<DebtProvider>().loadAll();
                  Navigator.pop(ctx);
                  _loadStatement();
                }
              }
            },
            child: const Text('سداد وتحديث الكشف', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, double amount, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('${amount.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        )
      ],
    );
  }
}
