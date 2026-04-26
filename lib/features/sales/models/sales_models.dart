import 'package:flutter/material.dart';
import 'package:mohassib/core/database/database_helper.dart';
import 'package:mohassib/features/products/models/product_model.dart';
import 'package:mohassib/features/products/provider/product_provider.dart';

// ─────────────────────────────────────────────
// CART ITEM MODEL
// ─────────────────────────────────────────────
class CartItem {
  final int productId;
  final String name;
  final double buyPrice;
  double sellPrice; // قابل للتعديل (خصم سعر)
  double quantity;
  String unit;
  double conversionFactor; // كم حبة تحتوي هذه الوحدة
  final double maxQuantity; // الكمية المتاحة بالوحدة الصغرى

  CartItem({
    required this.productId,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
    required this.unit,
    this.conversionFactor = 1.0,
    required this.maxQuantity,
  });

  double get lineTotal => sellPrice * quantity;
  double get lineProfit => (sellPrice - buyPrice) * quantity;

  Map<String, dynamic> toSaleItemMap() => {
    'product_id': productId,
    'product_name': '$name ($unit)',
    'buy_price': buyPrice * conversionFactor,
    'sell_price': sellPrice,
    'quantity': quantity,
    'total': lineTotal,
    'stock_qty': quantity * conversionFactor, // الكمية الحقيقية المخصومة من المخزن
  };
}

// ─────────────────────────────────────────────
// SALE MODEL
// ─────────────────────────────────────────────
class SaleModel {
  final int? id;
  final int saleNumber;
  final double totalAmount;
  final double discount;
  final double taxAmount;
  final String paymentMethod;
  final String? customerName;
  final String? customerPhone;
  final String? notes;
  final String status;
  final String createdAt;
  final List<SaleItemModel> items;

  const SaleModel({
    this.id,
    required this.saleNumber,
    required this.totalAmount,
    required this.discount,
    required this.taxAmount,
    required this.paymentMethod,
    this.customerName,
    this.customerPhone,
    this.notes,
    this.status = 'completed',
    required this.createdAt,
    this.items = const [],
  });

  double get subtotal => totalAmount + discount - taxAmount;

  factory SaleModel.fromMap(Map<String, dynamic> m) {
    var itemsList = <SaleItemModel>[];
    if (m['items'] != null) {
      itemsList = (m['items'] as List).map((i) => SaleItemModel.fromMap(i)).toList();
    }
    return SaleModel(
      id: m['id'] as int?,
      saleNumber: m['sale_number'] as int,
      totalAmount: (m['total_amount'] as num).toDouble(),
      discount: (m['discount'] as num?)?.toDouble() ?? 0,
      taxAmount: (m['tax_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: m['payment_method'] as String,
      customerName: m['customer_name'] as String?,
      customerPhone: m['customer_phone'] as String?,
      notes: m['notes'] as String?,
      status: m['status'] as String? ?? 'completed',
      createdAt: m['created_at'] as String,
      items: itemsList,
    );
  }

  static String methodLabel(String method) {
    switch (method) {
      case 'cash': return 'نقداً';
      case 'transfer': return 'تحويل بنكي';
      case 'card': return 'بطاقة';
      case 'debt': return 'آجل (دين)';
      case 'split': return 'دفع متعدد';
      default: return method;
    }
  }

  static IconData methodIcon(String method) {
    switch (method) {
      case 'cash': return Icons.money;
      case 'transfer': return Icons.account_balance_wallet;
      case 'card': return Icons.credit_card;
      case 'debt': return Icons.menu_book;
      default: return Icons.call_split;
    }
  }
}

class SaleItemModel {
  final int? id;
  final int saleId;
  final int productId;
  final String productName;
  final double buyPrice;
  final double sellPrice;
  final double quantity;
  final double total;

  const SaleItemModel({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
    required this.total,
  });

  factory SaleItemModel.fromMap(Map<String, dynamic> m) => SaleItemModel(
    id: m['id'] as int?,
    saleId: m['sale_id'] as int,
    productId: m['product_id'] as int,
    productName: m['product_name'] as String,
    buyPrice: (m['buy_price'] as num).toDouble(),
    sellPrice: (m['sell_price'] as num).toDouble(),
    quantity: (m['quantity'] as num).toDouble(),
    total: (m['total'] as num).toDouble(),
  );
}

// ─────────────────────────────────────────────
// CART SESSION (Multi-basket support)
// ─────────────────────────────────────────────
class CartSession {
  final int id;
  List<CartItem> items;
  double discount;
  String? lastError;

  CartSession({
    required this.id,
    this.items = const [],
    this.discount = 0,
    this.lastError,
  });
}

// ─────────────────────────────────────────────
// CART PROVIDER (POS Engine)
// ─────────────────────────────────────────────
class CartProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  final List<CartSession> _sessions = List.generate(5, (i) => CartSession(id: i + 1, items: []));
  int _currentSessionIndex = 0;
  
  bool isProcessing = false;
  double _taxRate = 0; 

  int get currentSessionIndex => _currentSessionIndex;
  List<CartSession> get sessions => _sessions;
  CartSession get activeSession => _sessions[_currentSessionIndex];

  List<CartItem> get items => activeSession.items;
  bool get isEmpty => activeSession.items.isEmpty;
  int get itemCount => activeSession.items.length;
  String? get lastError => activeSession.lastError;

  double get subtotal => activeSession.items.fold(0.0, (s, i) => s + i.lineTotal);
  double get taxAmount => subtotal * (_taxRate / 100);
  double get discount => activeSession.discount;
  double get total => subtotal + taxAmount - activeSession.discount;
  double get totalProfit => activeSession.items.fold(0.0, (s, i) => s + i.lineProfit);

  void switchSession(int index) {
    if (index >= 0 && index < _sessions.length) {
      _currentSessionIndex = index;
      notifyListeners();
    }
  }
  Future<void> loadTaxRate() async {
    final settings = await _db.getStoreSettings();
    if (settings != null) {
      _taxRate = (settings['tax_rate'] as num?)?.toDouble() ?? 0;
      notifyListeners();
    }
  }

  // ── إضافة منتج للسلة
  void addProduct(ProductModel p, {double qty = 1}) {
    final session = activeSession;
    final i = session.items.indexWhere((x) => x.productId == p.id);
    if (i != -1) {
      final current = session.items[i].quantity;
      if (current + qty > p.quantity) {
        session.lastError = 'الكمية المتاحة: ${p.quantity} ${p.unit}';
        notifyListeners();
        return;
      }
      session.items[i].quantity += qty;
    } else {
      if (p.isOutOfStock) {
        session.lastError = 'المنتج نفذ من المخزون';
        notifyListeners();
        return;
      }
      session.items.add(CartItem(
        productId: p.id!,
        name: p.name,
        buyPrice: p.buyPrice,
        sellPrice: p.sellPrice,
        quantity: qty,
        unit: p.unit,
        conversionFactor: 1.0,
        maxQuantity: p.quantity,
      ));
    }
    session.lastError = null;
    notifyListeners();
  }

  void removeItem(int productId) {
    activeSession.items.removeWhere((x) => x.productId == productId);
    notifyListeners();
  }

  void updateQuantity(int productId, double newQty) {
    final session = activeSession;
    final i = session.items.indexWhere((x) => x.productId == productId);
    if (i == -1) return;
    if (newQty <= 0) {
      session.items.removeAt(i);
    } else if (newQty * session.items[i].conversionFactor > session.items[i].maxQuantity) {
      session.lastError = 'الحد الأقصى المتاح: ${session.items[i].maxQuantity} حبة';
    } else {
      session.items[i].quantity = newQty;
      session.lastError = null;
    }
    notifyListeners();
  }

  void updateUnit(int productId, String unitName, double factor, double newPrice) {
    final session = activeSession;
    final i = session.items.indexWhere((x) => x.productId == productId);
    if (i != -1) {
      session.items[i].unit = unitName;
      session.items[i].conversionFactor = factor;
      session.items[i].sellPrice = newPrice;
      notifyListeners();
    }
  }

  void updateSellPrice(int productId, double newPrice) {
    final i = activeSession.items.indexWhere((x) => x.productId == productId);
    if (i != -1) {
      activeSession.items[i].sellPrice = newPrice;
      notifyListeners();
    }
  }

  void setDiscount(double d) {
    activeSession.discount = d.clamp(0, subtotal);
    notifyListeners();
  }

  void clearCart() {
    activeSession.items = [];
    activeSession.discount = 0;
    activeSession.lastError = null;
    notifyListeners();
  }

  // ── إتمام البيع (atomic)
  Future<int?> checkout({
    required String paymentMethod,
    required ProductProvider productProvider,
    String? customerName,
    String? customerPhone,
    int? customerId,
    String? notes,
  }) async {
    if (isProcessing || activeSession.items.isEmpty) return null;
    isProcessing = true;
    activeSession.lastError = null;
    notifyListeners();

    try {
      final saleId = await _db.processSale(
        items: activeSession.items.map((i) => i.toSaleItemMap()).toList(),
        paymentMethod: paymentMethod,
        totalAmount: total,
        discount: activeSession.discount,
        taxAmount: taxAmount,
        customerName: customerName,
        customerPhone: customerPhone,
        customerId: customerId,
        notes: notes,
      );

      // تحديث المخزون في الذاكرة فوراً
      for (final item in activeSession.items) {
        productProvider.deductStock(item.productId, item.quantity * item.conversionFactor);
      }

      clearCart();
      return saleId;
    } catch (e) {
      activeSession.lastError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }
}
