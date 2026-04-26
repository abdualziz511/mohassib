import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../models/currency_model.dart';

class CurrencyProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<CurrencyModel> _currencies = [];
  bool isLoading = false;

  List<CurrencyModel> get currencies => _currencies;
  
  CurrencyModel? get yerCurrency => _currencies.firstWhere((c) => c.code == 'YER', orElse: () => _currencies.first);

  Future<void> loadAll() async {
    isLoading = true;
    notifyListeners();
    final db = await _db.database;
    final rows = await db.query('currencies', orderBy: 'is_default DESC, name ASC');
    _currencies = rows.map(CurrencyModel.fromMap).toList();
    isLoading = false;
    notifyListeners();
  }

  Future<void> updateExchangeRate(int id, double newRate) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.update('currencies', {
      'exchange_rate': newRate,
      'updated_at': now,
    }, where: 'id = ?', whereArgs: [id]);
    
    final index = _currencies.indexWhere((c) => c.id == id);
    if (index != -1) {
      // تحديث محلي سريع
      _currencies[index] = CurrencyModel(
        id: _currencies[index].id,
        code: _currencies[index].code,
        name: _currencies[index].name,
        exchangeRate: newRate,
        symbol: _currencies[index].symbol,
        isDefault: _currencies[index].isDefault,
        updatedAt: now,
      );
      notifyListeners();
    }
  }

  double getRateFor(int? currencyId) {
    if (currencyId == null) return 1.0;
    return _currencies.firstWhere((c) => c.id == currencyId, orElse: () => yerCurrency!).exchangeRate;
  }
}
