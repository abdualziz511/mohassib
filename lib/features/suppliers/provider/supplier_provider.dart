import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../models/supplier_model.dart';

class SupplierProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<SupplierModel> _suppliers = [];
  bool isLoading = false;

  List<SupplierModel> get suppliers => _suppliers;

  Future<void> loadAll() async {
    isLoading = true;
    notifyListeners();
    final rows = await _db.getAllSuppliers();
    
    // Auto-sync legacy debts
    for (var r in rows) {
      await _db.syncSupplierDebts(r['id'] as int, r['name'] as String);
    }
    
    final syncedRows = await _db.getAllSuppliers();
    _suppliers = syncedRows.map(SupplierModel.fromMap).toList();
    isLoading = false;
    notifyListeners();
  }

  Future<bool> addSupplier(SupplierModel s) async {
    try {
      final db = await _db.database;
      final existing = await db.query('suppliers', where: 'name = ?', whereArgs: [s.name.trim()], limit: 1);
      if (existing.isNotEmpty) return false;

      final id = await _db.insertSupplier(s.toMap());
      await _db.syncSupplierDebts(id, s.name);
      await loadAll();
      return true;
    } catch (_) { return false; }
  }

  Future<void> updateBalanceLocally(int supplierId, double amount) async {
    final i = _suppliers.indexWhere((s) => s.id == supplierId);
    if (i != -1) {
      _suppliers[i] = _suppliers[i].copyWith(
        currentBalance: _suppliers[i].currentBalance + amount,
      );
      notifyListeners();
    }
  }

  Future<double> payDebtBulk(int supplierId, double amount, String notes) async {
    final excess = await _db.paySupplierDebtBulk(supplierId, amount, notes);
    await loadAll();
    return excess;
  }
}
