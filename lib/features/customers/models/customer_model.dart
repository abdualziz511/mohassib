class CustomerModel {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final double currentBalance;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const CustomerModel({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.currentBalance = 0.0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> m) => CustomerModel(
    id: m['id'] as int?,
    name: m['name'] as String,
    phone: m['phone'] as String?,
    address: m['address'] as String?,
    currentBalance: (m['current_balance'] as num?)?.toDouble() ?? 0.0,
    notes: m['notes'] as String?,
    createdAt: m['created_at'] as String,
    updatedAt: m['updated_at'] as String,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'current_balance': currentBalance,
    'notes': notes,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
