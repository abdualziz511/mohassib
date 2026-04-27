import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:mohassib/features/home/home_provider.dart';
import 'package:mohassib/features/products/ui/add_product_screen.dart';
import 'package:mohassib/features/expenses/ui/expenses_screen.dart';
import 'package:mohassib/features/debts/ui/debts_screen.dart';
import 'package:mohassib/features/sales/ui/pos_screen.dart';
import 'package:mohassib/features/products/provider/product_provider.dart';
import 'package:mohassib/features/expenses/models/expense_model.dart';
import 'package:mohassib/features/debts/models/debt_model.dart';
import 'package:mohassib/features/sales/models/sales_models.dart';
import 'package:mohassib/features/products/ui/products_screen.dart';
import 'package:mohassib/features/sales/ui/sales_history_screen.dart';
import 'package:mohassib/features/settings/ui/settings_screen.dart';
import 'package:mohassib/features/purchases/ui/purchases_screen.dart';
import 'package:mohassib/features/suppliers/ui/suppliers_screen.dart';
import 'package:mohassib/features/customers/ui/customers_screen.dart';
import 'package:mohassib/features/reports/ui/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isCircularChart = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HomeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111116) : const Color(0xFFF5F7FB);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      drawer: _buildDrawer(context, isDark, hp),
      body: SafeArea(
        child: hp.isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : RefreshIndicator(
              onRefresh: () => hp.loadDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderBar(isDark, hp),
                    _buildDateAndTrialCard(isDark),
                    _buildSummaryHeaderRow(context, isDark),
                    
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isCircularChart 
                        ? _buildCircularProfitCard(isDark, hp) 
                        : _buildLineProfitCard(isDark, hp),
                    ),
                    
                    const SizedBox(height: 16),
                    _buildDebtCard(isDark, hp),
                    const SizedBox(height: 24),
                    _buildQuickActions(context, isDark),
                    const SizedBox(height: 32),
                    _buildRecentOperations(isDark, hp),
                    const SizedBox(height: 80), 
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildHeaderBar(bool isDark, HomeProvider hp) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── الجهة اليمنى (القائمة والمعلومات) - تظهر يميناً لأننا في وضع RTL
          Row(
            children: [
              InkWell(
                 onTap: () => _scaffoldKey.currentState?.openDrawer(),
                 child: _buildCircleButton(Icons.menu, isDark)
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent, width: 2)
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  radius: 18,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, // عرض النصوص بذكاء
                children: [
                  Text(hp.storeName, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  Text(hp.ownerName, style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 10)),
                ],
              ),
            ],
          ),

          // ── الجهة اليسرى (الإشعارات والرسائل) - تظهر يساراً
          Row(
            children: [
              _buildCircleButton(Icons.mail_outline, isDark),
              const SizedBox(width: 12),
              _buildCircleButton(Icons.notifications_none, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1A1A24) : Colors.white;
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _buildDateAndTrialCard(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1A1A24) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final now = DateTime.now();
    final dateStr = intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(now);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 8),
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             decoration: BoxDecoration(
               color: cardColor, 
               borderRadius: BorderRadius.circular(16),
               boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
             ),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                  Text(dateStr, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 18),
               ]
             )
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162A32) : const Color(0xFFEAF5F8), 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueAccent.withOpacity(isDark ? 0.2 : 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('ترقية الحساب', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    Text(
                      'أنت تستخدم النسخة \nالمجانية الكاملة \nبدون قيود حالياً',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: isDark ? Colors.white : Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.stars, color: Colors.blueAccent, size: 24),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryHeaderRow(BuildContext context, bool isDark) {
    final titleColor = isDark ? Colors.white : Colors.black87;
    final btnColor = isDark ? const Color(0xFF1A1A24) : Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildActionBtn(Icons.tune, btnColor, () {}),
              const SizedBox(width: 8),
              _buildActionBtn(_isCircularChart ? Icons.pie_chart : Icons.bar_chart, 
                _isCircularChart ? Colors.blueAccent.withOpacity(0.2) : btnColor, 
                () => setState(() => _isCircularChart = !_isCircularChart)),
            ]
          ),
          Text('ملخص عمليات اليوم', style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ]
      )
    );
  }

  Widget _buildActionBtn(IconData icon, Color bg, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: Colors.blueAccent, size: 20),
    ),
  );

  Widget _buildCircularProfitCard(bool isDark, HomeProvider hp) {
    final cardColor = isDark ? const Color(0xFF1A1A24) : Colors.white;
    final innerColor = isDark ? const Color(0xFF111116) : const Color(0xFFF5F7FB);
    final titleColor = isDark ? Colors.white : Colors.black87;

    return Container(
      key: const ValueKey(1),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: innerColor, width: 20),
              ),
              child: Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                      Text('صافي الربح', style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 12)),
                      Text('${hp.todayProfit.toStringAsFixed(0)} ${hp.currency}', style: const TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                   ]
                 )
              )
            )
          ),
          const SizedBox(height: 32),
          _statsGrid(isDark, hp, titleColor, innerColor),
        ]
      )
    );
  }

  Widget _buildLineProfitCard(bool isDark, HomeProvider hp) {
    final cardColor = isDark ? const Color(0xFF1A1A24) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.05), blurRadius: 40)] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('صافي الربح اليوم', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.trending_up, color: Colors.greenAccent, size: 24),
                  const SizedBox(width: 8),
                  Text('${hp.todayProfit.toStringAsFixed(0)} ${hp.currency}', style: TextStyle(color: titleColor, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 60, child: Center(child: Text('الرسم البياني متاح في التقارير', style: TextStyle(color: Colors.grey, fontSize: 10)))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _summaryItem('المصروفات', hp.todayExpenses, Colors.redAccent, isDark, titleColor, cardColor),
              const SizedBox(width: 12),
              _summaryItem('المبيعات', hp.todaySales, Colors.blueAccent, isDark, titleColor, cardColor),
            ]
          ),
        )
      ],
    );
  }

  Widget _summaryItem(String label, double val, Color color, bool isDark, Color titleColor, Color cardColor) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(val >= 0 ? Icons.trending_up : Icons.trending_down, color: color, size: 20),
          Text(label, style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        Text('${val.toStringAsFixed(0)}', style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    ),
  );

  Widget _statsGrid(bool isDark, HomeProvider hp, Color titleColor, Color innerColor) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: innerColor, borderRadius: BorderRadius.circular(16)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _smallStat('الربح', hp.todayProfit, Colors.greenAccent, isDark, titleColor),
      _vDiv(isDark),
      _smallStat('المصروفات', hp.todayExpenses, Colors.redAccent, isDark, titleColor),
      _vDiv(isDark),
      _smallStat('المبيعات', hp.todaySales, Colors.blueAccent, isDark, titleColor),
    ]),
  );

  Widget _vDiv(bool isDark) => Container(width: 1, height: 30, color: isDark ? Colors.white10 : Colors.black12);

  Widget _smallStat(String l, double v, Color c, bool isDark, Color tc) => Column(children: [
    Row(children: [
      Text(l, style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 10)),
      const SizedBox(width: 4),
      CircleAvatar(radius: 3, backgroundColor: c),
    ]),
    const SizedBox(height: 4),
    Text(v.toStringAsFixed(0), style: TextStyle(color: tc, fontWeight: FontWeight.bold, fontSize: 14)),
  ]);

  Widget _buildDebtCard(bool isDark, HomeProvider hp) {
    final cardColor = isDark ? const Color(0xFF1A1A24) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ديون مستحقة لك', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
          Text('${hp.totalReceivable.toStringAsFixed(0)} ${hp.currency}', style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        Container(width: 1, height: 40, color: Colors.white10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('التزامات عليك', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
          Text('${hp.totalPayable.toStringAsFixed(0)} ${hp.currency}', style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton('إضافة منتج', Icons.add_box, Colors.tealAccent.shade400, isDark, () {
             showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, 
              builder: (_) => ChangeNotifierProvider.value(value: context.read<ProductProvider>(), child: const AddEditProductSheet()));
          }),
          _buildActionButton('إضافة مصروف', Icons.money_off, Colors.redAccent, isDark, () {
            showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, 
              builder: (_) => _AddExpenseQuickSheet(ep: context.read<ExpenseProvider>()));
          }),
          _buildActionButton('إضافة دين', Icons.group_add, Colors.orangeAccent, isDark, () {
            showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, 
              builder: (_) => _AddDebtQuickSheet(dp: context.read<DebtProvider>()));
          }),
          _buildActionButton('نقطة بيع', Icons.shopping_cart, Colors.blueAccent, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const POSScreen()))),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, bool isDark, VoidCallback onTap) {
    final cardColor = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: isDark ? Border.all(color: color.withOpacity(0.3)) : null),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRecentOperations(bool isDark, HomeProvider hp) {
    final titleColor = isDark ? Colors.white : Colors.black87;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('آخر المبيعات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (hp.recentSales.isEmpty) 
            const Center(child: Text('لا توجد مبيعات اليوم', style: TextStyle(color: Colors.grey, fontSize: 12)))
          else
            ...hp.recentSales.map((s) => _saleItem(s, isDark)),
        ]
      )
    );
  }

  Widget _saleItem(SaleModel s, bool isDark) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Text('${s.totalAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
      const Spacer(),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('فاتورة #${s.saleNumber}', style: const TextStyle(color: Colors.white, fontSize: 13)),
        Text(s.paymentMethod == 'cash' ? 'نقداً' : 'آجل', style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ]),
      const SizedBox(width: 12),
      const Icon(Icons.receipt, color: Colors.white24),
    ]),
  );

  Widget _buildDrawer(BuildContext context, bool isDark, HomeProvider hp) {
    final cardColor = isDark ? const Color(0xFF1A1A24) : Colors.white;
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF111116) : const Color(0xFFF5F7FB),
      child: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          InkWell(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.redAccent)),
          Text(hp.storeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ])),
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          _drawerItem('الإحصائيات والتقارير', Icons.insights, Colors.cyan, onTap: () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
          }),
          _drawerItem('سجل المبيعات', Icons.history, Colors.blue, onTap: () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryScreen()));
          }),
          _drawerItem('المصروفات', Icons.money_off, Colors.red, onTap: () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen()));
          }),
          _drawerItem('الديون', Icons.account_balance_wallet, Colors.orange, onTap: () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtsScreen()));
          }),
          _drawerItem('المنتجات', Icons.inventory_2, Colors.teal, onTap: () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()));
          }),
          _drawerItem('المشتريات', Icons.shopping_bag, Colors.purpleAccent, onTap: () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchasesScreen()));
          }),
          _drawerItem('الموردين', Icons.local_shipping, Colors.indigoAccent, onTap: () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const SuppliersScreen()));
          }),
          _drawerItem('العملاء', Icons.people, Colors.lightGreen, onTap: () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen()));
          }),
          const Divider(color: Colors.white10),
          _drawerItem('إعدادات المتجر', Icons.settings, Colors.grey, onTap: () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
          _drawerItem('عن التطبيق', Icons.info_outline, Colors.grey),
        ])),
      ])),
    );
  }

  Widget _drawerItem(String t, IconData i, Color c, {VoidCallback? onTap}) => ListTile(
    onTap: onTap,
    title: Text(t, style: const TextStyle(color: Colors.white, fontSize: 14)),
    trailing: Icon(i, color: c),
  );
}

// ── Quick Sheets (Temporary implementation or Bridge) ──────────
class _AddExpenseQuickSheet extends StatefulWidget {
  final ExpenseProvider ep;
  const _AddExpenseQuickSheet({required this.ep});
  @override
  State<_AddExpenseQuickSheet> createState() => _AddExpenseQuickSheetState();
}
class _AddExpenseQuickSheetState extends State<_AddExpenseQuickSheet> {
  final _amt = TextEditingController();
  String _cat = 'أخرى';
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
    decoration: const BoxDecoration(color: Color(0xFF1E1E2A), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('إضافة مصروف سريع', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(controller: _amt, textAlign: TextAlign.right, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'المبلغ', hintStyle: TextStyle(color: Colors.grey))),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: () async {
        final val = double.tryParse(_amt.text) ?? 0;
        if (val > 0) {
          await widget.ep.addExpense(val, _cat);
          if (mounted) {
            context.read<HomeProvider>().refresh();
            Navigator.pop(context);
          }
        }
      }, style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, minimumSize: const Size(double.infinity, 50)), child: const Text('حفظ', style: TextStyle(color: Colors.white))),
    ]),
  );
}

class _AddDebtQuickSheet extends StatefulWidget {
  final DebtProvider dp;
  const _AddDebtQuickSheet({required this.dp});
  @override
  State<_AddDebtQuickSheet> createState() => _AddDebtQuickSheetState();
}
class _AddDebtQuickSheetState extends State<_AddDebtQuickSheet> {
  final _name = TextEditingController();
  final _amt = TextEditingController();
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
    decoration: const BoxDecoration(color: Color(0xFF1E1E2A), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('إضافة دين سريع', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(controller: _name, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'الاسم', hintStyle: TextStyle(color: Colors.grey))),
      TextField(controller: _amt, textAlign: TextAlign.right, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'المبلغ', hintStyle: TextStyle(color: Colors.grey))),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: () async {
        final val = double.tryParse(_amt.text) ?? 0;
        if (val > 0 && _name.text.isNotEmpty) {
          await widget.dp.addDebt(type: 'receivable', personName: _name.text, amount: val);
          if (mounted) {
            context.read<HomeProvider>().refresh();
            Navigator.pop(context);
          }
        }
      }, style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, minimumSize: const Size(double.infinity, 50)), child: const Text('حفظ', style: TextStyle(color: Colors.white))),
    ]),
  );
}
