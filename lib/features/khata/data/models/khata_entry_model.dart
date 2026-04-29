import '../../domain/entities/khata_entry_entity.dart';

class KhataEntryModel extends KhataEntryEntity {
  KhataEntryModel({
    required super.id,
    required super.customerId,
    required super.amount,
    required super.type,
    super.notes,
    required super.date,
  });

  factory KhataEntryModel.fromMap(Map<String, dynamic> map) {
    return KhataEntryModel(
      id: map['id'],
      customerId: map['customerId'],
      amount: map['amount']?.toDouble() ?? 0.0,
      type: map['type'] == 'gave' ? EntryType.gave : EntryType.got,
      notes: map['notes'],
      date: DateTime.parse(map['date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'amount': amount,
      'type': type == EntryType.gave ? 'gave' : 'got',
      'notes': notes,
      'date': date.toIso8601String(),
    };
  }
}