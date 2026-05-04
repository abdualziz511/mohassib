class ProductUnitModel {
  final int? id;
  final int productId;
  final String unitName;
  final double conversionFactor; // كم حبة في هذه الوحدة
  final bool isPurchaseUnit;
  final bool isSaleUnit;
  final double priceMarkup; // زيادة سعر اختيارية لهذه الوحدة
  final String? barcode;
  final double sellPrice; // سعر البيع المستقل لهذه الوحدة إن وجد

  const ProductUnitModel({
    this.id,
    required this.productId,
    required this.unitName,
    this.conversionFactor = 1.0,
    this.isPurchaseUnit = false,
    this.isSaleUnit = false,
    this.priceMarkup = 0.0,
    this.barcode,
    this.sellPrice = 0.0,
  });

  factory ProductUnitModel.fromMap(Map<String, dynamic> m) => ProductUnitModel(
    id: m['id'] as int?,
    productId: m['product_id'] as int,
    unitName: m['unit_name'] as String,
    conversionFactor: (m['conversion_factor'] as num).toDouble(),
    isPurchaseUnit: (m['is_purchase_unit'] as int?) == 1,
    isSaleUnit: (m['is_sale_unit'] as int?) == 1,
    priceMarkup: (m['price_markup'] as num?)?.toDouble() ?? 0.0,
    barcode: m['barcode'] as String?,
    sellPrice: (m['sell_price'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'product_id': productId,
    'unit_name': unitName,
    'conversion_factor': conversionFactor,
    'is_purchase_unit': isPurchaseUnit ? 1 : 0,
    'is_sale_unit': isSaleUnit ? 1 : 0,
    'price_markup': priceMarkup,
    'barcode': barcode,
    'sell_price': sellPrice,
  };
}
