// lib/features/expenses/presentation/pages/expense_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/expense_card.dart';
import '../../data/models/expense_model.dart';
import '../state/expense_provider.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        // 🚀 EXPLICIT BACK BUTTON
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Expense History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      // 🚀 DESKTOP FIX: Center and ConstrainedBox
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('expenses')
                .stream(primaryKey: ['id'])
                .order('date', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final expenses = snapshot.data!.map((e) => ExpenseModel.fromJson(e)).toList();

              return ListView.builder(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  bool showDateHeader = false;

                  // Check if we should show date header (Today, Yesterday, etc.)
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
                      if (showDateHeader) _buildDateHeader(expense.date),

                      // 🚀 Dismissible Widget For Swipe-to-Delete
                      Dismissible(
                        key: Key(expense.id ?? expense.hashCode.toString()),
                        direction: DismissDirection.endToStart, // Sirf Right se Left swipe hoga
                        // 🚀 NEW: Desktop/Mobile safety check before delete
                        confirmDismiss: (direction) => _showDeleteConfirmation(context),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444), // Expense Red
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                        ),
                        onDismissed: (direction) {
                          if (expense.id != null) {
                            // Delete function call
                            ref.read(expenseProvider.notifier).deleteExpense(expense.id!);

                            // Success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Expense deleted successfully'),
                                backgroundColor: Color(0xFF10B981), // Success Green
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        // 🚀 InkWell For Tap-to-Edit
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          // 🚀 DESKTOP FIX: Hover effect
                          hoverColor: Colors.grey.shade100,
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

  Widget _buildDateHeader(DateTime date) {
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
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
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

  // 🚀 Safety confirmation dialog
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