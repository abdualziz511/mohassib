class PurchaseModel {
  final int? id;
  final int? supplierId;
  final String? supplierName;
  final String invoiceNumber;
  final double totalAmount;
  final double paidAmount;
  final String paymentMethod; // cash | debt
  final String? notes;
  final String createdAt;
  final List<PurchaseItemModel> items;

  const PurchaseModel({
    this.id,
    this.supplierId,
    this.supplierName,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  double get remainingAmount => totalAmount - paidAmount;
  bool get isFullPaid => remainingAmount <= 0;

  factory PurchaseModel.fromMap(Map<String, dynamic> m) => PurchaseModel(
    id: m['id'] as int?,
    supplierId: m['supplier_id'] as int?,
    supplierName: m['supplier_name'] as String?,
    invoiceNumber: m['invoice_number'] as String,
    totalAmount: (m['total_amount'] as num).toDouble(),
    paidAmount: (m['paid_amount'] as num).toDouble(),
    paymentMethod: m['payment_method'] as String,
    notes: m['notes'] as String?,
    createdAt: m['created_at'] as String,
    items: [], // يتم تحميلها بشكل منفصل
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'supplier_id': supplierId,
    'invoice_number': invoiceNumber,
    'total_amount': totalAmount,
    'paid_amount': paidAmount,
    'payment_method': paymentMethod,
    'notes': notes,
    'created_at': createdAt,
  };
}

class PurchaseItemModel {
  final int? id;
  final int purchaseId;
  final int productId;
  final String productName;
  final double buyPrice;
  final double quantity;
  final String unit;
  final double total;
  final double conversionFactor;
  final double stockQty; // الكمية بالوحدة الصغرى

  const PurchaseItemModel({
    this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.buyPrice,
    required this.quantity,
    required this.unit,
    this.conversionFactor = 1.0,
    required this.total,
    required this.stockQty,
  });

  factory PurchaseItemModel.fromMap(Map<String, dynamic> m) => PurchaseItemModel(
    id: m['id'] as int?,
    purchaseId: m['purchase_id'] as int,
    productId: m['product_id'] as int,
    productName: m['product_name'] as String,
    buyPrice: (m['buy_price'] as num).toDouble(),
    quantity: (m['quantity'] as num).toDouble(),
    unit: m['unit'] as String? ?? 'قطعة',
    conversionFactor: (m['conversion_factor'] as num?)?.toDouble() ?? 1.0,
    total: (m['total'] as num).toDouble(),
    stockQty: (m['stock_qty'] as num?)?.toDouble() ?? (m['quantity'] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'purchase_id': purchaseId,
    'product_id': productId,
    'product_name': productName,
    'buy_price': buyPrice,
    'quantity': quantity,
    'unit': unit,
    'conversion_factor': conversionFactor,
    'total': total,
    'stock_qty': stockQty,
  };
}
