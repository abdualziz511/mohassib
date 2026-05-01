import 'package:flutter/material.dart';
import 'package:mohassib/features/products/models/product_model.dart';
import 'package:mohassib/features/products/models/product_unit_model.dart';
import 'package:mohassib/features/products/repository/product_repository.dart';
import 'package:mohassib/core/database/database_helper.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repo = ProductRepository();

  List<ProductModel> _all = [];
  List<ProductModel> _filtered = [];
  bool isLoading = false;
  String _searchQuery = '';

  List<ProductModel> get products => _searchQuery.isEmpty ? _all : _filtered;
  int get totalCount => _all.length;
  double get totalBuyValue => _all.fold(0.0, (s, p) => s + p.totalBuyValue);
  double get totalSellValue => _all.fold(0.0, (s, p) => s + p.totalSellValue);
  double get expectedProfit => totalSellValue - totalBuyValue;
  List<ProductModel> get lowStockProducts => _all.where((p) => p.isLowStock).toList();

  Future<void> loadAll() async {
    isLoading = true;
    notifyListeners();
    final productsRaw = await _repo.getAll();
    
    // تحميل الوحدات لكل منتج
    List<ProductModel> enriched = [];
    for (var p in productsRaw) {
      final unitRows = await DatabaseHelper.instance.getProductUnits(p.id!);
      final units = unitRows.map(ProductUnitModel.fromMap).toList();
      enriched.add(p.copyWith(units: units));
    }

    _all = enriched;
    _filtered = [];
    _searchQuery = '';
    isLoading = false;
    notifyListeners();
  }

  Future<void> searchProducts(String query) async {
    _searchQuery = query.trim();
    if (_searchQuery.isEmpty) {
      _filtered = [];
    } else {
      _filtered = await _repo.search(_searchQuery);
    }
    notifyListeners();
  }

  Future<ProductModel?> getByBarcode(String barcode) => _repo.getByBarcode(barcode);

  Future<bool> addProduct(ProductModel p, List<ProductUnitModel> units) async {
    try {
      final id = await _repo.insertWithUnits(p, units);
      final newP = p.copyWith(id: id, units: units);
      _all.insert(0, newP);
      notifyListeners();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> updateProduct(ProductModel p, List<ProductUnitModel> units) async {
    try {
      await _repo.updateWithUnits(p, units);
      final i = _all.indexWhere((x) => x.id == p.id);
      if (i != -1) { 
        _all[i] = p.copyWith(units: units); 
        notifyListeners(); 
      }
      return true;
    } catch (_) { return false; }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _repo.delete(id);
      _all.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (_) { return false; }
  }

  void deductStock(int productId, double qty) {
    final i = _all.indexWhere((p) => p.id == productId);
    if (i != -1) {
      _all[i] = _all[i].copyWith(quantity: (_all[i].quantity - qty).clamp(0, double.infinity));
      notifyListeners();
    }
  }

  void updateProductStockLocally(int productId, double qty, double newBuyPrice) {
    final i = _all.indexWhere((p) => p.id == productId);
    if (i != -1) {
      _all[i] = _all[i].copyWith(
        quantity: _all[i].quantity + qty,
        buyPrice: newBuyPrice,
      );
      notifyListeners();
    }
  }

  Color stockColor(ProductModel p) {
    if (p.isOutOfStock) return Colors.red;
    if (p.isLowStock) return Colors.orange;
    return Colors.green;
  }
}
