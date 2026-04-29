import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/khata_entry_entity.dart';

import '../state/state/khata_provider.dart';

class AddTransactionDialog extends ConsumerStatefulWidget {
  final String customerId;
  final bool isGave; // True if 'DIVE', False if 'LIYE'

  const AddTransactionDialog({super.key, required this.customerId, required this.isGave});

  @override
  ConsumerState<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = widget.isGave ? Colors.red.shade600 : const Color(0xFF10B981);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          widget.isGave ? 'You Gave (DIVE)' : 'You Got (LIYE)',
          style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Amount (Rs.)',
                prefixIcon: Icon(Icons.currency_rupee, color: themeColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Notes (e.g. Sugar, Flour)',
                prefixIcon: const Icon(Icons.note_add_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              if (_amountController.text.isNotEmpty) {
                final double? amount = double.tryParse(_amountController.text);
                if (amount == null) return;

                final entry = KhataEntryEntity(
                  id: const Uuid().v4(),
                  customerId: widget.customerId,
                  amount: amount,
                  type: widget.isGave ? EntryType.gave : EntryType.got,
                  notes: _notesController.text,
                  date: DateTime.now(),
                );

                // 1. Cloud par entry save aur balance update
                await ref.read(customerProvider.notifier).addEntry(entry);

                // 2. Is specific customer ki history list ko bhi refresh karo
                ref.read(transactionProvider(widget.customerId).notifier).loadTransactions();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Rs. $amount added successfully!'),
                      backgroundColor: themeColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}