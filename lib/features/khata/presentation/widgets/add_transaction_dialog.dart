// lib/features/khata/presentation/widgets/add_transaction_dialog.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/theme_provider.dart'; // 🚀 Theme Provider Import
import '../../domain/entities/khata_entry_entity.dart';
import '../state/state/khata_provider.dart';

class AddTransactionDialog extends ConsumerStatefulWidget {
  final String customerId;
  final bool isGave;
  final KhataEntryEntity? existingEntry;

  const AddTransactionDialog({
    super.key,
    required this.customerId,
    required this.isGave,
    this.existingEntry,
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
    final themeState = ref.watch(themeProvider); // 🚀 Watch Global Theme

    // Transaction type color (Gave = Red, Got = Green/Theme)
    final Color transactionColor = widget.isGave ? Colors.red.shade600 : const Color(0xFF10B981);

    String title = widget.isGave ? 'Amount Given (Out)' : 'Amount Received (In)';
    if (isEditMode) title = 'Edit Transaction';

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center( // 🚀 Desktop Alignment
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450), // 🚀 Dialog width fix
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: transactionColor)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    autofocus: !isEditMode,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: transactionColor),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.currency_rupee, color: transactionColor),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: transactionColor, width: 2),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'Add notes (Items, details...)',
                      prefixIcon: const Icon(Icons.description_outlined),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: themeState.primaryColor, width: 2),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: transactionColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () async {
                  final double? amount = double.tryParse(_amountController.text);
                  if (amount != null && amount > 0) {
                    if (isEditMode) {
                      final updatedEntry = widget.existingEntry!.copyWith(
                        amount: amount,
                        notes: _notesController.text.trim(),
                      );
                      await ref.read(customerProvider.notifier).updateEntry(updatedEntry);
                    } else {
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
                          backgroundColor: transactionColor,
                          behavior: SnackBarBehavior.floating,
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
        ),
      ),
    );
  }
}