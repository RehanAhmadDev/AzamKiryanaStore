import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_model.dart';
import '../state/expense_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  // 🚀 Naya optional parameter add kiya gaya hai
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

  // 🚀 initState mein purana data auto-fill karne ka logic
  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      _titleController.text = widget.existingExpense!.title;
      _amountController.text = widget.existingExpense!.amount.toStringAsFixed(0);
      _notesController.text = widget.existingExpense!.notes ?? '';

      // Safety check: Agar purani category list mein nahi hai toh Misc set kar do
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
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title and amount')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final isUpdating = widget.existingExpense != null;

    // 🚀 Model create karna (Naya ya Update)
    final expenseData = ExpenseModel(
      id: isUpdating ? widget.existingExpense!.id : null, // ID update ke liye zaroori hai
      title: _titleController.text,
      amount: amount,
      category: _selectedCategory,
      date: isUpdating ? widget.existingExpense!.date : DateTime.now(), // Purani date barqarar rakhni hai
      notes: _notesController.text,
    );

    if (isUpdating) {
      // Update logic (Ye function humein provider mein banana hoga)
      await ref.read(expenseProvider.notifier).updateExpense(expenseData);
    } else {
      // Add logic
      await ref.read(expenseProvider.notifier).addExpense(expenseData);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUpdating ? 'Expense Updated Successfully!' : 'Expense Added Successfully!'),
          backgroundColor: const Color(0xFF10B981), // Success Green
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseProvider);
    final isUpdating = widget.existingExpense != null; // Screen mode check

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        // 🚀 Title change hoga mode ke hisaab se
        title: Text(isUpdating ? 'Edit Expense' : 'New Expense',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("What was the expense for?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            _buildInputFields(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUpdating ? const Color(0xFF6366F1) : const Color(0xFFEF4444), // Update ke liye blue color
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: state.isLoading ? null : _submitData,
                child: state.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                // 🚀 Button text change hoga
                    : Text(isUpdating ? 'Update Expense' : 'Save Expense',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        _customTextField(controller: _titleController, label: 'Title', icon: Icons.title),
        const SizedBox(height: 16),
        _customTextField(controller: _amountController, label: 'Amount (Rs.)', icon: Icons.money, isNumber: true),
        const SizedBox(height: 16),

        // Category Selection
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _customTextField(controller: _notesController, label: 'Notes (Optional)', icon: Icons.notes, maxLines: 3),
      ],
    );
  }

  Widget _customTextField({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5)),
      ),
    );
  }
}