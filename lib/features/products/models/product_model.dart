import 'product_unit_model.dart';

class ProductModel {
  final int? id;
  final String name;
  final String? barcode;
  final double buyPrice;      // السعر بعملة الشراء
  final double sellPrice;     // السعر بالريال اليمني
  final double wholesalePrice; // سعر الجملة بالريال اليمني
  final double quantity;      // الكمية بالوحدة الأساسية (الأصغر)
  final String unit;          // اسم الوحدة الأساسية
  final int? currencyId;      // معرف عملة الشراء
  final bool isLiquid;
  final bool isByWeight;
  final double lowStockAlert;
  final String? imagePath;
  final bool isActive;
  final List<ProductUnitModel> units; // الوحدات المتوفرة

  const ProductModel({
    this.id,
    required this.name,
    this.barcode,
    required this.buyPrice,
    required this.sellPrice,
    this.wholesalePrice = 0.0,
    required this.quantity,
    this.unit = 'قطعة',
    this.currencyId,
    this.isLiquid = false,
    this.isByWeight = false,
    this.lowStockAlert = 5.0,
    this.imagePath,
    this.isActive = true,
    this.units = const [],
  });

  // حساب التكلفة بالريال اليمني بناءً على سعر الصرف
  double calculateBuyPriceInYer(double exchangeRate) => buyPrice * exchangeRate;

  // Getters للتحقق من حالة المخزون
  bool get isOutOfStock => quantity <= 0;
  bool get isLowStock => quantity <= lowStockAlert && quantity > 0;
  
  double get totalBuyValue => buyPrice * quantity; // ملاحظة: تعتمد على عملة الشراء
  double get totalSellValue => sellPrice * quantity;
  
  // الربح للقطعة الواحدة (بفرض أن البيع دائماً باليمني)
  // ملاحظة: إذا كان الشراء بعملة أخرى، يجب ضرب buyPrice في سعر الصرف أولاً
  // لكن للتبسيط حالياً سنفترض الربح المباشر أو نضيف معامل الصرف لاحقاً
  double get profit => sellPrice - buyPrice; 

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'barcode': barcode,
    'buy_price': buyPrice,
    'sell_price': sellPrice,
    'wholesale_price': wholesalePrice,
    'quantity': quantity,
    'unit': unit,
    'currency_id': currencyId,
    'is_liquid': isLiquid ? 1 : 0,
    'is_by_weight': isByWeight ? 1 : 0,
    'low_stock_alert': lowStockAlert,
    'image_path': imagePath,
    'is_active': isActive ? 1 : 0,
  };

  factory ProductModel.fromMap(Map<String, dynamic> m, {List<ProductUnitModel> units = const []}) => ProductModel(
    id: m['id'] as int?,
    name: m['name'] as String,
    barcode: m['barcode'] as String?,
    buyPrice: (m['buy_price'] as num).toDouble(),
    sellPrice: (m['sell_price'] as num).toDouble(),
    wholesalePrice: (m['wholesale_price'] as num?)?.toDouble() ?? 0.0,
    quantity: (m['quantity'] as num).toDouble(),
    unit: m['unit'] as String? ?? 'قطعة',
    currencyId: m['currency_id'] as int?,
    isLiquid: (m['is_liquid'] as int?) == 1,
    isByWeight: (m['is_by_weight'] as int?) == 1,
    lowStockAlert: (m['low_stock_alert'] as num?)?.toDouble() ?? 5.0,
    imagePath: m['image_path'] as String?,
    isActive: (m['is_active'] as int?) == 1,
    units: units,
  );

  ProductModel copyWith({
    int? id, String? name, String? barcode,
    double? buyPrice, double? sellPrice, double? wholesalePrice,
    double? quantity, String? unit, int? currencyId,
    bool? isLiquid, bool? isByWeight, double? lowStockAlert,
    String? imagePath, bool? isActive, List<ProductUnitModel>? units,
  }) => ProductModel(
    id: id ?? this.id,
    name: name ?? this.name,
    barcode: barcode ?? this.barcode,
    buyPrice: buyPrice ?? this.buyPrice,
    sellPrice: sellPrice ?? this.sellPrice,
    wholesalePrice: wholesalePrice ?? this.wholesalePrice,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    currencyId: currencyId ?? this.currencyId,
    isLiquid: isLiquid ?? this.isLiquid,
    isByWeight: isByWeight ?? this.isByWeight,
    lowStockAlert: lowStockAlert ?? this.lowStockAlert,
    imagePath: imagePath ?? this.imagePath,
    isActive: isActive ?? this.isActive,
    units: units ?? this.units,
  );
}
