import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/khata_entry_entity.dart';
import '../state/state/khata_provider.dart';

class AddTransactionDialog extends ConsumerStatefulWidget {
  final String customerId;
  final bool isGave;
  final KhataEntryEntity? existingEntry; // 🚀 Added for Edit Mode

  const AddTransactionDialog({
    super.key,
    required this.customerId,
    required this.isGave,
    this.existingEntry, // Agar ye null na hua to edit mode chalega
  });

  @override
  ConsumerState<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    // 🚀 Purana data load karna agar edit kar rahe hain
    _amountController = TextEditingController(
      text: widget.existingEntry?.amount.toStringAsFixed(0) ?? '',
    );
    _notesController = TextEditingController(
      text: widget.existingEntry?.notes ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.existingEntry != null;
    final Color themeColor = widget.isGave ? Colors.red.shade600 : const Color(0xFF10B981);

    // Title update based on mode
    String title = widget.isGave ? 'Amount Given (Out)' : 'Amount Received (In)';
    if (isEditMode) title = 'Edit Transaction';

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: themeColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: !isEditMode,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixIcon: Icon(Icons.currency_rupee, color: themeColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Add notes (Items, details...)',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            onPressed: () async {
              final double? amount = double.tryParse(_amountController.text);
              if (amount != null && amount > 0) {
                if (isEditMode) {
                  // 🚀 UPDATE LOGIC
                  final updatedEntry = widget.existingEntry!.copyWith(
                    amount: amount,
                    notes: _notesController.text.trim(),
                  );
                  await ref.read(customerProvider.notifier).updateEntry(updatedEntry);
                } else {
                  // 🚀 ADD LOGIC
                  final entry = KhataEntryEntity(
                    id: const Uuid().v4(),
                    customerId: widget.customerId,
                    amount: amount,
                    type: widget.isGave ? EntryType.gave : EntryType.got,
                    notes: _notesController.text.trim(),
                    date: DateTime.now(),
                  );
                  await ref.read(customerProvider.notifier).addEntry(entry);
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditMode ? 'Transaction updated' : 'Transaction saved'),
                      backgroundColor: themeColor,
                    ),
                  );
                }
              }
            },
            child: Text(
              isEditMode ? 'Update' : 'Confirm',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}