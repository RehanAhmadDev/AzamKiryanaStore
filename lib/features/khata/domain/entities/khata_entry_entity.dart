enum EntryType { gave, got } // gave = DIVE, got = LIYE

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
}