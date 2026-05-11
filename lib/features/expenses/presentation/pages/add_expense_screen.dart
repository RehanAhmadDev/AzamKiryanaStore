// lib/features/expenses/presentation/pages/add_expense_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart'; // 🚀 Theme Provider Import
import '../../data/models/expense_model.dart';
import '../state/expense_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final ExpenseModel? existingExpense;

  const AddExpenseScreen({super.key, this.existingExpense});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'Utility';

  final List<String> _categories = ['Utility', 'Food', 'Rent', 'Salary', 'Misc'];

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      _titleController.text = widget.existingExpense!.title;
      _amountController.text = widget.existingExpense!.amount.toStringAsFixed(0);
      _notesController.text = widget.existingExpense!.notes ?? '';

      if (_categories.contains(widget.existingExpense!.category)) {
        _selectedCategory = widget.existingExpense!.category;
      } else {
        _selectedCategory = 'Misc';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    if (_titleController.text.trim().isEmpty || _amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title and amount')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final isUpdating = widget.existingExpense != null;

    final expenseData = ExpenseModel(
      id: isUpdating ? widget.existingExpense!.id : null,
      title: _titleController.text.trim(),
      amount: amount,
      category: _selectedCategory,
      date: isUpdating ? widget.existingExpense!.date : DateTime.now(),
      notes: _notesController.text.trim(),
    );

    if (isUpdating) {
      await ref.read(expenseProvider.notifier).updateExpense(expenseData);
    } else {
      await ref.read(expenseProvider.notifier).addExpense(expenseData);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUpdating ? 'Expense Updated Successfully!' : 'Expense Added Successfully!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 Theme watch
    final themeState = ref.watch(themeProvider);
    final state = ref.watch(expenseProvider);
    final isUpdating = widget.existingExpense != null;

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
        title: Text(isUpdating ? 'Edit Expense' : 'New Expense',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: themeState.primaryColor, // 🚀 Dynamic Theme Color
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          // 🚀 DESKTOP WIDTH FIX: 1200px as requested
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView( // 🚀 Scroller Fix
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("What was the expense for?",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: _buildInputFields(themeState.primaryColor),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeState.primaryColor, // 🚀 Dynamic Theme Color
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                    ),
                    onPressed: state.isLoading ? null : _submitData,
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isUpdating ? 'Update Expense' : 'Save Expense',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputFields(Color primaryColor) {
    return Column(
      children: [
        _customTextField(controller: _titleController, label: 'Title', icon: Icons.title, primaryColor: primaryColor),
        const SizedBox(height: 16),
        _customTextField(controller: _amountController, label: 'Amount (Rs.)', icon: Icons.money, isNumber: true, primaryColor: primaryColor),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _customTextField(controller: _notesController, label: 'Notes (Optional)', icon: Icons.notes, maxLines: 3, primaryColor: primaryColor),
      ],
    );
  }

  Widget _customTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
    bool isNumber = false,
    int maxLines = 1
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.6), size: 20),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 1.5) // 🚀 Theme Color Border
        ),
      ),
    );
  }
}