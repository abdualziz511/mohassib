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

  Future<void> addCustomer(CustomerModel customer) async {
    final id = await _db.database.then((db) => db.insert('customers', customer.toMap()));
    await _db.syncCustomerDebts(id, customer.name);
    await loadAll();
  }

  Future<void> payDebtBulk(int customerId, double amount, String notes) async {
    await _db.payCustomerDebtBulk(customerId, amount, notes);
    await loadAll();
  }
}
