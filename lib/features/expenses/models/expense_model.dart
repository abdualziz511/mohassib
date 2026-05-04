import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';

// ─────────────────────────────────────────────
// EXPENSE MODEL
// ─────────────────────────────────────────────
class ExpenseModel {
  final int? id;
  final double amount;
  final String category;
  final String? notes;
  final String createdAt;

  // أيقونات وألوان ثابتة للتصنيفات المعروفة
  static const Map<String, IconData> categoryIcons = {
    'إيجار': Icons.home,
    'كهرباء': Icons.flash_on,
    'نقل': Icons.local_shipping,
    'الإلتزامات': Icons.handshake,
    'منتجات منتهية الصلاحية': Icons.no_food,
    'رواتب': Icons.people,
    'صيانة': Icons.build,
    'أخرى': Icons.more_horiz,
  };

  static const Map<String, Color> categoryColors = {
    'إيجار': Colors.purple,
    'كهرباء': Colors.amber,
    'نقل': Colors.blue,
    'الإلتزامات': Colors.teal,
    'منتجات منتهية الصلاحية': Colors.red,
    'رواتب': Colors.indigo,
    'صيانة': Colors.brown,
    'أخرى': Colors.grey,
  };

  const ExpenseModel({
    this.id,
    required this.amount,
    required this.category,
    this.notes,
    required this.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> m) => ExpenseModel(
    id: m['id'] as int?,
    amount: (m['amount'] as num).toDouble(),
    category: m['category'] as String,
    notes: m['notes'] as String?,
    createdAt: m['created_at'] as String,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'amount': amount,
    'category': category,
    'notes': notes,
  };
}

// ─────────────────────────────────────────────
// EXPENSE PROVIDER
// ─────────────────────────────────────────────
class ExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<ExpenseModel> _all = [];
  List<ExpenseModel> _filtered = [];
  List<String> _categories = [];
  bool isLoading = false;
  String _activeCategory = 'الكل';
  String? _activeDateFilter;

  List<ExpenseModel> get expenses => _filtered.isNotEmpty || _activeCategory != 'الكل' || _activeDateFilter != null
      ? _filtered
      : _all;

  List<String> get categories => _categories.isEmpty
      ? ['إيجار', 'كهرباء', 'نقل', 'الإلتزامات', 'رواتب', 'صيانة', 'أخرى']
      : _categories;

  double get totalAmount => expenses.fold(0, (s, e) => s + e.amount);
  String get activeCategory => _activeCategory;

  // تحميل التصنيفات من قاعدة البيانات
  Future<void> loadCategories() async {
    try {
      _categories = await _db.getExpenseCategories();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadAll({String? dateFilter, String? category}) async {
    isLoading = true;
    notifyListeners();
    _activeDateFilter = dateFilter;
    _activeCategory = category ?? 'الكل';
    // جلب التصنيفات والسجلات بالتوازي
    final results = await Future.wait([
      _db.getExpenses(
          dateFilter: dateFilter,
          category: _activeCategory == 'الكل' ? null : _activeCategory),
      _db.getExpenseCategories(),
    ]);
    _all = (results[0] as List<Map<String, dynamic>>)
        .map(ExpenseModel.fromMap)
        .toList();
    _categories = results[1] as List<String>;
    _filtered = _all;
    isLoading = false;
    notifyListeners();
  }

  Future<bool> addExpense(double amount, String category, {String? notes}) async {
    try {
      final id = await _db.insertExpense({'amount': amount, 'category': category, 'notes': notes});
      final e = ExpenseModel(id: id, amount: amount, category: category, notes: notes, createdAt: DateTime.now().toIso8601String());
      _all.insert(0, e);
      _applyFilter();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await _db.deleteExpense(id);
      _all.removeWhere((e) => e.id == id);
      _applyFilter();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> addCategory(String name) async {
    try {
      await _db.addExpenseCategory(name);
      _categories = await _db.getExpenseCategories();
      notifyListeners();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> deleteCategory(String name) async {
    try {
      await _db.deleteExpenseCategory(name);
      _categories = await _db.getExpenseCategories();
      notifyListeners();
      return true;
    } catch (_) { return false; }
  }

  void filter({String? category, String? dateFilter}) {
    _activeCategory = category ?? _activeCategory;
    _activeDateFilter = dateFilter ?? _activeDateFilter;
    _applyFilter();
  }

  void _applyFilter() {
    _filtered = _all.where((e) {
      final catMatch = _activeCategory == 'الكل' || e.category == _activeCategory;
      final dateMatch = _activeDateFilter == null || e.createdAt.startsWith(_activeDateFilter!);
      return catMatch && dateMatch;
    }).toList();
    notifyListeners();
  }
}
