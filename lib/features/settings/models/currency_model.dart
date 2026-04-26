class CurrencyModel {
  final int? id;
  final String code;
  final String name;
  final double exchangeRate;
  final String? symbol;
  final bool isDefault;
  final String updatedAt;

  const CurrencyModel({
    this.id,
    required this.code,
    required this.name,
    required this.exchangeRate,
    this.symbol,
    this.isDefault = false,
    required this.updatedAt,
  });

  factory CurrencyModel.fromMap(Map<String, dynamic> m) => CurrencyModel(
    id: m['id'] as int?,
    code: m['code'] as String,
    name: m['name'] as String,
    exchangeRate: (m['exchange_rate'] as num).toDouble(),
    symbol: m['symbol'] as String?,
    isDefault: (m['is_default'] as int?) == 1,
    updatedAt: m['updated_at'] as String,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'code': code,
    'name': name,
    'exchange_rate': exchangeRate,
    'symbol': symbol,
    'is_default': isDefault ? 1 : 0,
    'updated_at': updatedAt,
  };
}
