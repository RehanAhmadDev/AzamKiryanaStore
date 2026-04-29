class CustomerEntity {
  final String id;
  final String name;
  final String phone;
  final String type; // 'customer' ya 'vendor'
  final double totalBalance; // +ve (Lene hain), -ve (Dene hain)
  final DateTime createdAt;

  CustomerEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.totalBalance = 0.0,
    required this.createdAt,
  });
}