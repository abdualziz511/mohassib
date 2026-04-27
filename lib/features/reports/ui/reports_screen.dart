import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool isLoading = true;

  // اليوم
  double todaySales = 0;
  double todayProfit = 0;
  double todayExpenses = 0;
  int todayCount = 0;

  // الشهر
  double monthSales = 0;
  double monthProfit = 0;
  double monthExpenses = 0;
  int monthCount = 0;

  // المخزون
  int totalProducts = 0;
  int lowStockCount = 0;
  double inventoryBuyValue = 0;
  double inventorySellValue = 0;

  // الديون
  double totalReceivable = 0;
  double totalPayable = 0;

  // أعلى المنتجات مبيعاً
  List<Map<String, dynamic>> topProducts = [];

  // توزيع المصروفات
  List<Map<String, dynamic>> expensesByCategory = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => isLoading = true);
    final db = DatabaseHelper.instance;
    final raw = await db.database;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final monthStart = DateTime.now().toIso8601String().substring(0, 7); // YYYY-MM

    // ── اليوم ──
    final todayStats = await db.getDailyStats(today);
    todaySales    = todayStats['sales'] ?? 0;
    todayProfit   = todayStats['profit'] ?? 0;
    todayExpenses = todayStats['expenses'] ?? 0;
    todayCount    = (todayStats['count'] ?? 0).toInt();

    // ── الشهر ──
    final mSales = await raw.rawQuery('''
      SELECT COALESCE(SUM(total_amount),0) as total, COUNT(*) as cnt
      FROM sales WHERE created_at LIKE '$monthStart%' AND status='completed'
    ''');
    final mExp = await raw.rawQuery('''
      SELECT COALESCE(SUM(amount),0) as total
      FROM expenses WHERE created_at LIKE '$monthStart%'
    ''');
    final mProfit = await raw.rawQuery('''
      SELECT COALESCE(SUM((si.sell_price - si.buy_price)*si.quantity),0) as profit
      FROM sale_items si JOIN sales s ON s.id=si.sale_id
      WHERE s.created_at LIKE '$monthStart%' AND s.status='completed'
    ''');
    monthSales    = (mSales.first['total']  as num?)?.toDouble() ?? 0;
    monthCount    = (mSales.first['cnt']    as int?) ?? 0;
    monthExpenses = (mExp.first['total']    as num?)?.toDouble() ?? 0;
    monthProfit   = ((mProfit.first['profit'] as num?)?.toDouble() ?? 0) - monthExpenses;

    // ── المخزون ──
    final inv = await raw.rawQuery('''
      SELECT COUNT(*) as cnt, 
             COALESCE(SUM(buy_price*quantity),0) as buyVal,
             COALESCE(SUM(sell_price*quantity),0) as sellVal,
             SUM(CASE WHEN quantity<=low_stock_alert AND quantity>0 THEN 1 ELSE 0 END) as low
      FROM products WHERE is_active=1
    ''');
    totalProducts      = (inv.first['cnt']     as int?) ?? 0;
    lowStockCount      = (inv.first['low']     as int?) ?? 0;
    inventoryBuyValue  = (inv.first['buyVal']  as num?)?.toDouble() ?? 0;
    inventorySellValue = (inv.first['sellVal'] as num?)?.toDouble() ?? 0;

    // ── الديون ──
    final debts = await db.getDebtsSummary();
    totalReceivable = debts['receivable'] ?? 0;
    totalPayable    = debts['payable'] ?? 0;

    // ── أعلى المنتجات ──
    topProducts = await raw.rawQuery('''
      SELECT si.product_name, 
             SUM(si.stock_qty) as total_qty,
             SUM(si.total) as total_revenue
      FROM sale_items si
      JOIN sales s ON s.id=si.sale_id
      WHERE s.created_at LIKE '$monthStart%'
      GROUP BY si.product_name
      ORDER BY total_revenue DESC
      LIMIT 5
    ''');

    // ── المصروفات حسب الفئة ──
    expensesByCategory = await raw.rawQuery('''
      SELECT category, COALESCE(SUM(amount),0) as total
      FROM expenses WHERE created_at LIKE '$monthStart%'
      GROUP BY category
      ORDER BY total DESC
    ''');

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111116) : const Color(0xFFF5F7FB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A24) : Colors.white,
        elevation: 0,
        title: const Text('التقارير والإحصائيات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'اليوم والشهر'),
            Tab(text: 'المخزون'),
            Tab(text: 'الديون والمصروفات'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildSalesTab(isDark),
                _buildInventoryTab(isDark),
                _buildDebtsExpensesTab(isDark),
              ],
            ),
    );
  }

  // ── تبويب المبيعات ────────────────────────────────────────
  Widget _buildSalesTab(bool isDark) {
    final fmt = NumberFormat('#,##0', 'ar');
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('اليوم', Icons.today, Colors.blueAccent),
          const SizedBox(height: 8),
          Row(children: [
            _statCard('المبيعات', fmt.format(todaySales), 'ر.ي', Colors.blueAccent, Icons.point_of_sale, isDark),
            const SizedBox(width: 8),
            _statCard('الربح', fmt.format(todayProfit), 'ر.ي', Colors.greenAccent, Icons.trending_up, isDark),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _statCard('المصروفات', fmt.format(todayExpenses), 'ر.ي', Colors.redAccent, Icons.money_off, isDark),
            const SizedBox(width: 8),
            _statCard('عدد الفواتير', fmt.format(todayCount), 'فاتورة', Colors.orangeAccent, Icons.receipt_long, isDark),
          ]),
          const SizedBox(height: 24),
          _sectionTitle('هذا الشهر', Icons.calendar_month, Colors.purpleAccent),
          const SizedBox(height: 8),
          Row(children: [
            _statCard('إجمالي المبيعات', fmt.format(monthSales), 'ر.ي', Colors.blueAccent, Icons.bar_chart, isDark),
            const SizedBox(width: 8),
            _statCard('صافي الربح', fmt.format(monthProfit), 'ر.ي', Colors.greenAccent, Icons.account_balance, isDark),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _statCard('المصروفات', fmt.format(monthExpenses), 'ر.ي', Colors.redAccent, Icons.receipt, isDark),
            const SizedBox(width: 8),
            _statCard('عدد الفواتير', fmt.format(monthCount), 'فاتورة', Colors.orangeAccent, Icons.list_alt, isDark),
          ]),
          const SizedBox(height: 24),
          if (topProducts.isNotEmpty) ...[
            _sectionTitle('الأكثر مبيعاً هذا الشهر', Icons.star, Colors.amber),
            const SizedBox(height: 8),
            _buildTopProductsList(isDark, fmt),
          ],
        ],
      ),
    );
  }

  // ── تبويب المخزون ─────────────────────────────────────────
  Widget _buildInventoryTab(bool isDark) {
    final fmt = NumberFormat('#,##0', 'ar');
    final expectedProfit = inventorySellValue - inventoryBuyValue;
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('تحليل المخزون', Icons.inventory_2, Colors.tealAccent),
          const SizedBox(height: 8),
          Row(children: [
            _statCard('إجمالي الأصناف', fmt.format(totalProducts), 'صنف', Colors.tealAccent, Icons.category, isDark),
            const SizedBox(width: 8),
            _statCard('منتجات قليلة', fmt.format(lowStockCount), 'صنف', Colors.orangeAccent, Icons.warning_amber, isDark),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _statCard('قيمة الشراء', fmt.format(inventoryBuyValue), 'ر.ي', Colors.redAccent, Icons.shopping_bag, isDark),
            const SizedBox(width: 8),
            _statCard('قيمة البيع', fmt.format(inventorySellValue), 'ر.ي', Colors.blueAccent, Icons.sell, isDark),
          ]),
          const SizedBox(height: 12),
          _bigCard('الربح المتوقع من المخزون', fmt.format(expectedProfit), 'ر.ي',
              expectedProfit >= 0 ? Colors.greenAccent : Colors.redAccent, isDark),
        ],
      ),
    );
  }

  // ── تبويب الديون والمصروفات ───────────────────────────────
  Widget _buildDebtsExpensesTab(bool isDark) {
    final fmt = NumberFormat('#,##0', 'ar');
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('ملخص الديون', Icons.account_balance_wallet, Colors.orangeAccent),
          const SizedBox(height: 8),
          Row(children: [
            _statCard('ديون لك', fmt.format(totalReceivable), 'ر.ي', Colors.greenAccent, Icons.arrow_downward, isDark),
            const SizedBox(width: 8),
            _statCard('التزامات عليك', fmt.format(totalPayable), 'ر.ي', Colors.redAccent, Icons.arrow_upward, isDark),
          ]),
          const SizedBox(height: 8),
          _bigCard(
            totalReceivable >= totalPayable ? 'أنت في وضع إيجابي' : 'أنت في وضع سلبي',
            fmt.format((totalReceivable - totalPayable).abs()),
            'ر.ي صافي',
            totalReceivable >= totalPayable ? Colors.greenAccent : Colors.redAccent,
            isDark,
          ),
          const SizedBox(height: 24),
          if (expensesByCategory.isNotEmpty) ...[
            _sectionTitle('المصروفات هذا الشهر حسب الفئة', Icons.pie_chart, Colors.redAccent),
            const SizedBox(height: 8),
            _buildExpensesBreakdown(isDark, fmt),
          ],
        ],
      ),
    );
  }

  // ── مكونات UI ──────────────────────────────────────────────
  Widget _sectionTitle(String t, IconData icon, Color color) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text(t, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(width: 8),
      Icon(icon, color: color, size: 18),
    ],
  );

  Widget _statCard(String label, String value, String unit, Color color, IconData icon, bool isDark) {
    final card = isDark ? const Color(0xFF1A1A24) : Colors.white;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
            Text(label, style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 11)),
          ]),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(unit, style: TextStyle(color: color, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _bigCard(String label, String value, String unit, Color color, bool isDark) {
    final card = isDark ? const Color(0xFF1A1A24) : Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(label, style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 12)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text(unit, style: TextStyle(color: color, fontSize: 13)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _buildTopProductsList(bool isDark, NumberFormat fmt) {
    final card = isDark ? const Color(0xFF1A1A24) : Colors.white;
    return Container(
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: topProducts.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
          final colors = [Colors.amber, Colors.grey, Colors.brown.shade300, Colors.blueAccent, Colors.tealAccent];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: colors[i % colors.length].withOpacity(0.2),
              child: Text('${i + 1}', style: TextStyle(color: colors[i % colors.length], fontWeight: FontWeight.bold)),
            ),
            title: Text(p['product_name'] ?? '', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            subtitle: Text('الكمية: ${fmt.format(p['total_qty'] ?? 0)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            trailing: Text('${fmt.format(p['total_revenue'] ?? 0)} ر.ي',
                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpensesBreakdown(bool isDark, NumberFormat fmt) {
    final total = expensesByCategory.fold(0.0, (s, e) => s + ((e['total'] as num?)?.toDouble() ?? 0));
    final card = isDark ? const Color(0xFF1A1A24) : Colors.white;
    final colors = [Colors.redAccent, Colors.orangeAccent, Colors.amber, Colors.purpleAccent, Colors.blueAccent, Colors.tealAccent, Colors.greenAccent, Colors.grey];
    return Container(
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: expensesByCategory.asMap().entries.map((e) {
          final cat = e.value;
          final amt = (cat['total'] as num?)?.toDouble() ?? 0;
          final pct = total > 0 ? (amt / total * 100) : 0.0;
          final color = colors[e.key % colors.length];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(cat['category'] ?? '', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Text('${fmt.format(amt)} ر.ي', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(width: 8),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? amt / total : 0,
                    color: color,
                    backgroundColor: color.withOpacity(0.1),
                    minHeight: 6,
                  ),
                )),
              ]),
            ]),
          );
        }).toList(),
      ),
    );
  }
}
