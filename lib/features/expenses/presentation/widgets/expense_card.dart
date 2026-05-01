import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/expense_entity.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseEntity expense;

  const ExpenseCard({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getCategoryColor(expense.category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            _getCategoryIcon(expense.category),
            color: _getCategoryColor(expense.category),
          ),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
        ),
        subtitle: Text(
          DateFormat('hh:mm a').format(expense.date),
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '- Rs. ${expense.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: Color(0xFFEF4444), // Expense Red
              ),
            ),
            if (expense.notes != null && expense.notes!.isNotEmpty)
              const Icon(Icons.notes_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Helpers for dynamic UI
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Colors.orange;
      case 'utility': return Colors.blue;
      case 'rent': return Colors.purple;
      case 'salary': return Colors.green;
      default: return Colors.redAccent;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Icons.fastfood_rounded;
      case 'utility': return Icons.lightbulb_rounded;
      case 'rent': return Icons.home_rounded;
      case 'salary': return Icons.payments_rounded;
      default: return Icons.category_rounded;
    }
  }
}