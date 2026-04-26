import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../products/models/product_model.dart';
import '../../products/provider/product_provider.dart';
import '../models/purchase_model.dart';

class PurchaseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<PurchaseItemModel> _cartItems = [];
  double _paidAmount = 0;
  int? _selectedSupplierId;
  String _invoiceNumber = '';
  String? _notes;
  String _paymentMethod = 'cash';
  bool isProcessing = false;

  List<PurchaseItemModel> get cartItems => _cartItems;
  double get paidAmount => _paidAmount;
  int? get selectedSupplierId => _selectedSupplierId;
  String get invoiceNumber => _invoiceNumber;
  String get paymentMethod => _paymentMethod;
  
  double get totalAmount => _cartItems.fold(0, (sum, item) => sum + item.total);
  double get remainingAmount => totalAmount - _paidAmount;

  void setInvoiceNumber(String val) {
    _invoiceNumber = val;
    notifyListeners();
  }

  void setSelectedSupplier(int? id) {
    _selectedSupplierId = id;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    if (method == 'cash') _paidAmount = totalAmount;
    notifyListeners();
  }

  void setPaidAmount(double amount) {
    _paidAmount = amount;
    notifyListeners();
  }

  void addProductToCart(ProductModel product, double qty, double buyPrice, {String? unit, double factor = 1.0}) {
    final unitName = unit ?? product.unit;
    final index = _cartItems.indexWhere((item) => item.productId == product.id && item.unit == unitName);
    if (index != -1) {
      final existing = _cartItems[index];
      final newQty = existing.quantity + qty;
      _cartItems[index] = PurchaseItemModel(
        purchaseId: 0,
        productId: product.id!,
        productName: product.name,
        buyPrice: buyPrice,
        quantity: newQty,
        unit: unitName,
        conversionFactor: factor,
        total: newQty * buyPrice,
        stockQty: newQty * factor,
      );
    } else {
      _cartItems.add(PurchaseItemModel(
        purchaseId: 0,
        productId: product.id!,
        productName: product.name,
        buyPrice: buyPrice,
        quantity: qty,
        unit: unitName,
        conversionFactor: factor,
        total: qty * buyPrice,
        stockQty: qty * factor,
      ));
    }
    if (_paymentMethod == 'cash') _paidAmount = totalAmount;
    notifyListeners();
  }

  void removeItem(int productId) {
    _cartItems.removeWhere((item) => item.productId == productId);
    if (_paymentMethod == 'cash') _paidAmount = totalAmount;
    notifyListeners();
  }

  void clearCart() {
    _cartItems = [];
    _paidAmount = 0;
    _selectedSupplierId = null;
    _invoiceNumber = '';
    _notes = null;
    notifyListeners();
  }

  Future<bool> savePurchase(ProductProvider productProvider) async {
    if (_cartItems.isEmpty || _invoiceNumber.isEmpty) return false;
    
    isProcessing = true;
    notifyListeners();

    try {
      final purchaseId = await _db.processPurchase(
        items: _cartItems.map((i) => i.toMap()).toList(),
        paymentMethod: _paymentMethod,
        totalAmount: totalAmount,
        paidAmount: _paidAmount,
        supplierId: _selectedSupplierId,
        invoiceNumber: _invoiceNumber,
        notes: _notes,
      );

      // تحديث المنتجات في الذاكرة
      for (final item in _cartItems) {
        productProvider.updateProductStockLocally(item.productId, item.stockQty, item.buyPrice / item.conversionFactor);
      }

      clearCart();
      return true;
    } catch (e) {
      debugPrint("Purchase Save Error: $e");
      return false;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }
}
