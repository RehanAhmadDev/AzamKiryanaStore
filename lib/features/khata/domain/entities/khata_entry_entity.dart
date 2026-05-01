enum EntryType { gave, got }

class KhataEntryEntity {
  final String id;
  final String customerId;
  final double amount;
  final EntryType type;
  final String? notes;
  final DateTime date;

  KhataEntryEntity({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    this.notes,
    required this.date,
  });

  // 🚀 FIXED: copyWith method added to resolve the error in Dialog
  KhataEntryEntity copyWith({
    String? id,
    String? customerId,
    double? amount,
    EntryType? type,
    String? notes,
    DateTime? date,
  }) {
    return KhataEntryEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      date: date ?? this.date,
    );
  }
}