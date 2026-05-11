// lib/features/expenses/presentation/pages/expense_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart'; // 🚀 Theme Provider Import
import '../widgets/expense_card.dart';
import '../../data/models/expense_model.dart';
import '../state/expense_provider.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 Theme watch
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Expense History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: themeState.primaryColor, // 🚀 Dynamic Theme Color
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          // 🚀 DESKTOP WIDTH FIX: 1200px for wide layout
          constraints: const BoxConstraints(maxWidth: 1200),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('expenses')
                .stream(primaryKey: ['id'])
                .order('date', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: themeState.primaryColor));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final expenses = snapshot.data!.map((e) => ExpenseModel.fromJson(e)).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  bool showDateHeader = false;

                  if (index == 0) {
                    showDateHeader = true;
                  } else {
                    final prevExpense = expenses[index - 1];
                    if (DateFormat('yyyy-MM-dd').format(expense.date) !=
                        DateFormat('yyyy-MM-dd').format(prevExpense.date)) {
                      showDateHeader = true;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDateHeader) _buildDateHeader(expense.date, themeState.primaryColor),

                      Dismissible(
                        key: Key(expense.id ?? expense.hashCode.toString()),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) => _showDeleteConfirmation(context),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                        ),
                        onDismissed: (direction) {
                          if (expense.id != null) {
                            ref.read(expenseProvider.notifier).deleteExpense(expense.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Expense deleted successfully'),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          hoverColor: themeState.primaryColor.withOpacity(0.05), // 🚀 Dynamic Hover
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddExpenseScreen(existingExpense: expense),
                              ),
                            );
                          },
                          child: ExpenseCard(expense: expense),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date, Color primaryColor) {
    String label;
    final now = DateTime.now();
    if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(now)) {
      label = "Today";
    } else if (DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)))) {
      label = "Yesterday";
    } else {
      label = DateFormat('EEEE, dd MMM').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor.withOpacity(0.8)), // 🚀 Theme Color Label
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_graph_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No Expenses Found', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Expense?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove this expense record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}