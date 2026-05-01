class CustomerEntity {
  final String id;
  final String name;
  final String phone;
  final String type; // 'customer' or 'vendor'
  final double totalBalance;
  final DateTime createdAt;

  CustomerEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    required this.totalBalance,
    required this.createdAt,
  });

  // 🚀 FIXED: Ye method add karne se 'add_customer_dialog.dart' ka error khatam ho jaye ga
  CustomerEntity copyWith({
    String? id,
    String? name,
    String? phone,
    String? type,
    double? totalBalance,
    DateTime? createdAt,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      totalBalance: totalBalance ?? this.totalBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}