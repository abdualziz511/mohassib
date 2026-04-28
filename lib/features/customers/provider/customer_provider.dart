import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../models/customer_model.dart';

class CustomerProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<CustomerModel> _customers = [];
  bool _isLoading = false;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query('customers', orderBy: 'name ASC');
    
    // Auto-sync legacy debts
    for (var m in maps) {
      await _db.syncCustomerDebts(m['id'] as int, m['name'] as String);
    }
    
    final List<Map<String, dynamic>> syncedMaps = await db.query('customers', orderBy: 'name ASC');
    _customers = syncedMaps.map((m) => CustomerModel.fromMap(m)).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addCustomer(CustomerModel customer) async {
    final db = await _db.database;
    final existing = await db.query('customers', where: 'name = ?', whereArgs: [customer.name.trim()], limit: 1);
    if (existing.isNotEmpty) return false;
    
    final id = await db.insert('customers', customer.toMap());
    await _db.syncCustomerDebts(id, customer.name);
    await loadAll();
    return true;
  }

  Future<double> payDebtBulk(int customerId, double amount, String notes) async {
    final excess = await _db.payCustomerDebtBulk(customerId, amount, notes);
    await loadAll();
    return excess;
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    final db = await _db.database;
    final existing = await db.query('customers', where: 'name = ? AND id != ?', whereArgs: [customer.name.trim(), customer.id], limit: 1);
    if (existing.isNotEmpty) return false;
    
    await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
    await db.rawUpdate('UPDATE debts SET person_name = ? WHERE customer_id = ?', [customer.name, customer.id]);
    await loadAll();
    return true;
  }

  Future<void> deleteCustomer(int id) async {
    final db = await _db.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    await loadAll();
  }
}
