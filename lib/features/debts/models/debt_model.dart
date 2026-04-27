import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../customers/models/customer_model.dart';
import '../../suppliers/models/supplier_model.dart';

// ─────────────────────────────────────────────
// DEBT MODEL — موحّد ومترابط
// ─────────────────────────────────────────────
class DebtModel {
  final int? id;
  final String type;       // 'receivable' = مدين لنا | 'payable' = علينا
  final String personName;
  final String? phone;
  final double amount;
  final double paidAmount;
  final String? reminderDate;
  final String? notes;
  final String status;     // pending | partial | paid
  final bool whatsappAlert;
  final int? customerId;
  final int? supplierId;
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
    this.customerId,
    this.supplierId,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remaining => (amount - paidAmount).clamp(0, double.infinity);
  bool get isPaid => status == 'paid' || remaining <= 0;
  bool get isReceivable => type == 'receivable';
  bool get isLinked => customerId != null || supplierId != null;

  Color get statusColor {
    if (isPaid) return Colors.green;
    if (status == 'partial') return Colors.orange;
    return Colors.redAccent;
  }

  String get statusLabel {
    if (isPaid) return 'مسدّد';
    if (status == 'partial') return 'جزئي';
    return 'معلّق';
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
    customerId: m['customer_id'] as int?,
    supplierId: m['supplier_id'] as int?,
    createdAt: m['created_at'] as String,
    updatedAt: m['updated_at'] as String,
  );

  Map<String, dynamic> toMap() => {
    'type': type,
    'person_name': personName,
    'phone': phone,
    'amount': amount,
    'paid_amount': paidAmount,
    'reminder_date': reminderDate,
    'notes': notes,
    'status': status,
    'whatsapp_alert': whatsappAlert ? 1 : 0,
    'customer_id': customerId,
    'supplier_id': supplierId,
  };

  DebtModel copyWith({
    double? paidAmount,
    String? status,
    String? updatedAt,
  }) =>
      DebtModel(
        id: id,
        type: type,
        personName: personName,
        phone: phone,
        amount: amount,
        paidAmount: paidAmount ?? this.paidAmount,
        reminderDate: reminderDate,
        notes: notes,
        status: status ?? this.status,
        whatsappAlert: whatsappAlert,
        customerId: customerId,
        supplierId: supplierId,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ─────────────────────────────────────────────
// DEBT PROVIDER — المحرك الرئيسي لنظام الديون
// ─────────────────────────────────────────────
class DebtProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<DebtModel> _receivable = [];
  List<DebtModel> _payable    = [];
  List<CustomerModel> _customers = [];
  List<SupplierModel> _suppliers = [];

  bool isLoading = false;
  String _searchQuery = '';

  List<DebtModel> get receivable => _applySearch(_receivable);
  List<DebtModel> get payable    => _applySearch(_payable);
  List<CustomerModel> get customers => _customers;
  List<SupplierModel> get suppliers => _suppliers;

  double get totalReceivable =>
      _receivable.where((d) => !d.isPaid).fold(0, (s, d) => s + d.remaining);
  double get totalPayable =>
      _payable.where((d) => !d.isPaid).fold(0, (s, d) => s + d.remaining);

  List<DebtModel> _applySearch(List<DebtModel> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where((d) =>
            d.personName.toLowerCase().contains(q) ||
            (d.phone ?? '').contains(q))
        .toList();
  }

  void search(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  Future<void> loadAll() async {
    isLoading = true;
    notifyListeners();
    try {
      final rawDb = await _db.database;

      // جلب الديون
      final recRows = await _db.getDebts(type: 'receivable');
      final payRows = await _db.getDebts(type: 'payable');
      _receivable = recRows.map(DebtModel.fromMap).toList();
      _payable    = payRows.map(DebtModel.fromMap).toList();

      // جلب العملاء والموردين للاقتراح عند الإضافة
      final custRows = await rawDb.query('customers', orderBy: 'name ASC');
      _customers = custRows.map((m) => CustomerModel.fromMap(m)).toList();

      final supRows = await rawDb.query('suppliers', orderBy: 'name ASC');
      _suppliers = supRows.map((m) => SupplierModel.fromMap(m)).toList();
    } catch (_) {}
    isLoading = false;
    notifyListeners();
  }

  // ── البحث عن عميل بالاسم ──────────────────────────────────
  List<CustomerModel> searchCustomers(String q) {
    if (q.trim().isEmpty) return _customers;
    final low = q.toLowerCase();
    return _customers.where((c) =>
        c.name.toLowerCase().contains(low) ||
        (c.phone ?? '').contains(q)).toList();
  }

  List<SupplierModel> searchSuppliers(String q) {
    if (q.trim().isEmpty) return _suppliers;
    final low = q.toLowerCase();
    return _suppliers.where((s) =>
        s.name.toLowerCase().contains(low) ||
        (s.phone ?? '').contains(q)).toList();
  }

  // ── إضافة دين مربوط بعميل موجود أو يُنشئ عميلاً جديداً ──
  Future<bool> addDebtWithCustomer({
    required String type,           // receivable | payable
    required String personName,
    String? phone,
    required double amount,
    String? notes,
    String? reminderDate,
    bool whatsappAlert = false,
    int? existingCustomerId,        // إذا اختار المستخدم من القائمة
    int? existingSupplierId,
    bool createNewPerson = false,   // إذا لم يوجد → إنشاء سجل جديد
  }) async {
    try {
      final db = await _db.database;
      final now = DateTime.now().toIso8601String();

      int? customerId = existingCustomerId;
      int? supplierId = existingSupplierId;

      // إنشاء شخص جديد إذا طُلب ذلك
      if (createNewPerson) {
        if (type == 'receivable') {
          customerId = await db.insert('customers', {
            'name': personName,
            'phone': phone,
            'current_balance': amount,
            'created_at': now,
            'updated_at': now,
          });
        } else {
          supplierId = await db.insert('suppliers', {
            'name': personName,
            'phone': phone,
            'current_balance': amount,
            'created_at': now,
            'updated_at': now,
          });
        }
      } else if (customerId != null) {
        // تحديث رصيد العميل الموجود
        await db.rawUpdate('''
          UPDATE customers SET current_balance = current_balance + ?, updated_at = ?
          WHERE id = ?
        ''', [amount, now, customerId]);

        // تحديث الاسم والهاتف في الذاكرة (للعرض)
        final idx = _customers.indexWhere((c) => c.id == customerId);
        if (idx != -1 && (phone != null && phone.isNotEmpty)) {
          await db.update('customers', {'phone': phone, 'updated_at': now},
              where: 'id = ?', whereArgs: [customerId]);
        }
      } else if (supplierId != null) {
        await db.rawUpdate('''
          UPDATE suppliers SET current_balance = current_balance + ?, updated_at = ?
          WHERE id = ?
        ''', [amount, now, supplierId]);
      }

      // إدراج الدين
      await db.insert('debts', {
        'type': type,
        'person_name': personName,
        'phone': phone,
        'amount': amount,
        'paid_amount': 0.0,
        'reminder_date': reminderDate,
        'notes': notes,
        'status': 'pending',
        'whatsapp_alert': whatsappAlert ? 1 : 0,
        'customer_id': customerId,
        'supplier_id': supplierId,
        'created_at': now,
        'updated_at': now,
      });

      await loadAll();
      return true;
    } catch (e) {
      debugPrint('addDebtWithCustomer error: $e');
      return false;
    }
  }

  // ── سداد دفعة على دين واحد ────────────────────────────────
  Future<bool> addPayment(int debtId, double amount, {String? notes}) async {
    try {
      await _db.addDebtPayment(debtId, amount, notes);
      await loadAll();
      return true;
    } catch (e) {
      debugPrint('addPayment error: $e');
      return false;
    }
  }

  // ── سداد كل الديون لشخص دفعةً واحدة (bulk) ──────────────
  Future<bool> payAllForPerson({
    required String personName,
    required String type,
    required double amount,
    required String notes,
    int? customerId,
    int? supplierId,
  }) async {
    try {
      if (type == 'receivable' && customerId != null) {
        await _db.payCustomerDebtBulk(customerId, amount, notes);
      } else if (type == 'payable' && supplierId != null) {
        await _db.paySupplierDebtBulk(supplierId, amount, notes);
      } else {
        // سداد مباشر على الديون باسم الشخص بدون ربط
        await _payByName(personName, type, amount, notes);
      }
      await loadAll();
      return true;
    } catch (e) {
      debugPrint('payAllForPerson error: $e');
      return false;
    }
  }

  // سداد ديون بالاسم (للديون غير المربوطة بعميل/مورد)
  Future<void> _payByName(
      String personName, String type, double amount, String notes) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();

    final rows = await db.query('debts',
        where: 'person_name = ? AND type = ? AND status != ?',
        whereArgs: [personName, type, 'paid'],
        orderBy: 'created_at ASC');

    double remaining = amount;
    for (final row in rows) {
      if (remaining <= 0) break;
      final debtId = row['id'] as int;
      final debtAmt = (row['amount'] as num).toDouble();
      final paid = (row['paid_amount'] as num).toDouble();
      final needed = debtAmt - paid;
      final pay = remaining >= needed ? needed : remaining;

      await db.insert('debt_payments',
          {'debt_id': debtId, 'amount': pay, 'notes': notes, 'created_at': now});

      final newPaid = paid + pay;
      final status = newPaid >= debtAmt ? 'paid' : 'partial';
      await db.update('debts',
          {'paid_amount': newPaid, 'status': status, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [debtId]);

      remaining -= pay;
    }
  }

  // ── حذف دين (مع تصحيح رصيد العميل / المورد) ─────────────
  Future<bool> deleteDebt(DebtModel debt) async {
    try {
      final db = await _db.database;
      final now = DateTime.now().toIso8601String();

      // استرداد الرصيد المتبقي قبل الحذف
      final remaining = debt.remaining;

      if (remaining > 0) {
        if (debt.customerId != null) {
          await db.rawUpdate('''
            UPDATE customers SET current_balance = current_balance - ?, updated_at = ?
            WHERE id = ?
          ''', [remaining, now, debt.customerId]);
        } else if (debt.supplierId != null) {
          await db.rawUpdate('''
            UPDATE suppliers SET current_balance = current_balance - ?, updated_at = ?
            WHERE id = ?
          ''', [remaining, now, debt.supplierId]);
        }
      }

      await db.delete('debts', where: 'id = ?', whereArgs: [debt.id]);
      await loadAll();
      return true;
    } catch (e) {
      debugPrint('deleteDebt error: $e');
      return false;
    }
  }

  // ── كشف حساب شخص كامل (ديون + مدفوعات مرتّبة) ───────────
  Future<List<Map<String, dynamic>>> getPersonStatement(
      String personName, String type) async {
    return await _db.getPersonStatement(personName, type);
  }

  // ── ملخص رصيد شخص ─────────────────────────────────────────
  Map<String, double> getPersonSummary(String personName, String type) {
    final list = type == 'receivable' ? _receivable : _payable;
    final debts =
        list.where((d) => d.personName == personName).toList();
    final totalDebt = debts.fold(0.0, (s, d) => s + d.amount);
    final totalPaid = debts.fold(0.0, (s, d) => s + d.paidAmount);
    return {
      'total': totalDebt,
      'paid': totalPaid,
      'remaining': totalDebt - totalPaid,
    };
  }

  // ── الحصول على id الشخص المرتبط (لكشف الحساب) ────────────
  int? getLinkedId(String personName, String type) {
    final list = type == 'receivable' ? _receivable : _payable;
    final debt = list.where((d) => d.personName == personName).firstOrNull;
    if (debt == null) return null;
    return type == 'receivable' ? debt.customerId : debt.supplierId;
  }
}
