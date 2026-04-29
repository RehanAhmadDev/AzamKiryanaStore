import '../../domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  CustomerModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.type,
    super.totalBalance,
    required super.createdAt,
  });

  // SQLite (Map) se Dart Object banane ke liye
  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      type: map['type'],
      totalBalance: map['totalBalance']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Dart Object se Map banane ke liye (SQLite mein save karne ke liye)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'type': type,
      'totalBalance': totalBalance,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}