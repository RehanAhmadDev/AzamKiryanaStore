class ExpenseEntity {
  final String? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;

  ExpenseEntity({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
  });
}