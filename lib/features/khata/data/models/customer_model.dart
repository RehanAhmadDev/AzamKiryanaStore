import '../../domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  CustomerModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.type,
    required super.totalBalance, // 🚀 Fixed: Added required modifier
    required super.createdAt,    // 🚀 Fixed: Added required modifier
  });

  // Supabase ya SQLite (Map) se Dart Object banane ke liye
  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      type: map['type'] ?? 'customer',
      // Supabase mein 'total_balance' hota hai, mapping check kar lein
      totalBalance: (map['total_balance'] ?? map['totalBalance'] ?? 0.0).toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : (map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now()),
    );
  }

  // Dart Object se Map banane ke liye (Database mein save karne ke liye)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'type': type,
      'total_balance': totalBalance,
      'created_at': createdAt.toIso8601String(),
    };
  }
}