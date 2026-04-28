import 'package:flutter/material.dart';
import 'package:mohassib/core/database/database_helper.dart';
import 'package:mohassib/features/sales/models/sales_models.dart';

// ─────────────────────────────────────────────
// HOME / DASHBOARD PROVIDER
// ─────────────────────────────────────────────
class HomeProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // اليوم
  double todaySales        = 0;
  double todayExpenses     = 0;
  double todayReturns      = 0;
  double todayGrossProfit  = 0;
  double todayProfit       = 0;
  double todayCount        = 0;

  // الديون
  double totalReceivable = 0;
  double totalPayable    = 0;

  // آخر المبيعات
  List<SaleModel> recentSales = [];

  // إعدادات المتجر
  String storeName    = 'متجري';
  String ownerName    = '';
  String currency     = 'ر.ي';

  bool isLoading = false;

  String get today => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> loadDashboard() async {
    isLoading = true;
    notifyListeners();

    // تشغيل الاستعلامات بالتوازي
    final results = await Future.wait([
      _db.getDailyStats(today),
      _db.getDebtsSummary(),
      _db.getSales(dateFilter: today),
      _db.getStoreSettings(),
    ]);

    final stats    = results[0] as Map<String, double>;
    final debts    = results[1] as Map<String, double>;
    final salesRows = results[2] as List<Map<String, dynamic>>;
    final settings = results[3] as Map<String, dynamic>?;

    todaySales        = stats['sales']         ?? 0;
    todayExpenses     = stats['expenses']      ?? 0;
    todayReturns      = stats['returns']       ?? 0;
    todayGrossProfit  = stats['gross_profit']  ?? 0;
    todayProfit       = stats['net_profit']    ?? 0;
    todayCount        = stats['count']         ?? 0;

    totalReceivable = debts['receivable'] ?? 0;
    totalPayable    = debts['payable']    ?? 0;

    recentSales = salesRows.take(10).map(SaleModel.fromMap).toList();

    if (settings != null) {
      storeName  = settings['store_name'] as String? ?? 'متجري';
      ownerName  = settings['owner_name'] as String? ?? '';
      currency   = settings['currency']   as String? ?? 'ر.ي';
    }

    isLoading = false;
    notifyListeners();
  }

  // يُستدعى بعد كل عملية بيع/مصروف/دين لتحديث الأرقام فوراً
  void refresh() => loadDashboard();
}
