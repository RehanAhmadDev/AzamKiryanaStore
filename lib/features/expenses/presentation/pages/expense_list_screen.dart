import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/expense_card.dart';
import '../../data/models/expense_model.dart';

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Expense History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('expenses')
            .stream(primaryKey: ['id'])
            .order('date', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                  ExpenseCard(expense: expense),
                ],
              );
            },
          );
        },
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
          Icon(Icons.auto_graph_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text('No Expenses Found', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
        ],
      ),
    );
  }
}