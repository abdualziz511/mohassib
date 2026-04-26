import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';

// ─────────────────────────────────────────────
// DEBT MODEL
// ─────────────────────────────────────────────
class DebtModel {
  final int? id;
  final String type; // 'receivable' = لي | 'payable' = علي
  final String personName;
  final String? phone;
  final double amount;
  final double paidAmount;
  final String? reminderDate;
  final String? notes;
  final String status; // pending | partial | paid
  final bool whatsappAlert;
  final String createdAt;
  final String updatedAt;

  const DebtModel({
    this.id,
    required this.type,
    required this.personName,
    this.phone,
    required this.amount,
    this.paidAmount = 0,
    this.reminderDate,
    this.notes,
    this.status = 'pending',
    this.whatsappAlert = false,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remaining => amount - paidAmount;
  bool get isPaid => status == 'paid';
  bool get isReceivable => type == 'receivable';

  Color get statusColor {
    if (isPaid) return Colors.green;
    if (status == 'partial') return Colors.orange;
    return Colors.redAccent;
  }

  String get statusLabel {
    if (isPaid) return 'مسدد';
    if (status == 'partial') return 'جزئي';
    return 'معلق';
  }

  factory DebtModel.fromMap(Map<String, dynamic> m) => DebtModel(
    id: m['id'] as int?,
    type: m['type'] as String,
    personName: m['person_name'] as String,
    phone: m['phone'] as String?,
    amount: (m['amount'] as num).toDouble(),
    paidAmount: (m['paid_amount'] as num?)?.toDouble() ?? 0,
    reminderDate: m['reminder_date'] as String?,
    notes: m['notes'] as String?,
    status: m['status'] as String? ?? 'pending',
    whatsappAlert: (m['whatsapp_alert'] as int?) == 1,
    createdAt: m['created_at'] as String,
    updatedAt: m['updated_at'] as String,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'type': type,
    'person_name': personName,
    'phone': phone,
    'amount': amount,
    'paid_amount': paidAmount,
    'reminder_date': reminderDate,
    'notes': notes,
    'status': status,
    'whatsapp_alert': whatsappAlert ? 1 : 0,
  };
}

// ─────────────────────────────────────────────
// DEBT PROVIDER
// ─────────────────────────────────────────────
class DebtProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<DebtModel> _receivable = []; // لي (عملاء)
  List<DebtModel> _payable    = []; // علي (التزامات)
  bool isLoading = false;
  String _searchQuery = '';

  List<DebtModel> get receivable => _applySearch(_receivable);
  List<DebtModel> get payable    => _applySearch(_payable);

  double get totalReceivable => _receivable.where((d) => !d.isPaid).fold(0, (s, d) => s + d.remaining);
  double get totalPayable    => _payable.where((d) => !d.isPaid).fold(0, (s, d) => s + d.remaining);

  List<DebtModel> _applySearch(List<DebtModel> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((d) => d.personName.contains(_searchQuery) || (d.phone ?? '').contains(_searchQuery)).toList();
  }

  Future<void> loadAll() async {
    isLoading = true;
    notifyListeners();
    final recRows = await _db.getDebts(type: 'receivable');
    final payRows = await _db.getDebts(type: 'payable');
    _receivable = recRows.map(DebtModel.fromMap).toList();
    _payable    = payRows.map(DebtModel.fromMap).toList();
    isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  Future<bool> addDebt({
    required String type,
    required String personName,
    String? phone,
    required double amount,
    String? reminderDate,
    String? notes,
    bool whatsappAlert = false,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final id = await _db.insertDebt({
        'type': type,
        'person_name': personName,
        'phone': phone,
        'amount': amount,
        'paid_amount': 0.0,
        'reminder_date': reminderDate,
        'notes': notes,
        'status': 'pending',
        'whatsapp_alert': whatsappAlert ? 1 : 0,
      });
      final debt = DebtModel(
        id: id, type: type, personName: personName,
        phone: phone, amount: amount, notes: notes,
        status: 'pending', whatsappAlert: whatsappAlert,
        createdAt: now, updatedAt: now,
      );
      if (type == 'receivable') _receivable.insert(0, debt);
      else _payable.insert(0, debt);
      notifyListeners();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> addPayment(int debtId, double amount, {String? notes}) async {
    try {
      await _db.addDebtPayment(debtId, amount, notes);
      // تحديث الذاكرة
      _updateDebtInMemory(debtId, amount);
      notifyListeners();
      return true;
    } catch (_) { return false; }
  }

  void _updateDebtInMemory(int debtId, double paidAmount) {
    for (final list in [_receivable, _payable]) {
      final i = list.indexWhere((d) => d.id == debtId);
      if (i != -1) {
        final d = list[i];
        final newPaid = d.paidAmount + paidAmount;
        final status = newPaid >= d.amount ? 'paid' : 'partial';
        list[i] = DebtModel(
          id: d.id, type: d.type, personName: d.personName,
          phone: d.phone, amount: d.amount, paidAmount: newPaid,
          reminderDate: d.reminderDate, notes: d.notes, status: status,
          whatsappAlert: d.whatsappAlert,
          createdAt: d.createdAt, updatedAt: DateTime.now().toIso8601String(),
        );
        return;
      }
    }
  }

  Future<bool> deleteDebt(int id) async {
    try {
      await _db.deleteDebt(id);
      _receivable.removeWhere((d) => d.id == id);
      _payable.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (_) { return false; }
  }
}
