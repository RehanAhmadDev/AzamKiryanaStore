// lib/features/khata/presentation/pages/customer_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_provider.dart'; // 🚀 Theme Provider Import
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/khata_entry_entity.dart';

import '../state/state/khata_provider.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/add_customer_dialog.dart';
import 'pdf_preview_screen.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final CustomerEntity customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 Theme State Watch
    final themeState = ref.watch(themeProvider);
    final transactionState = ref.watch(transactionProvider(customer.id));
    final customerListState = ref.watch(customerProvider);

    CustomerEntity currentCustomer = customer;
    if (customerListState.value != null) {
      final matches = customerListState.value!.where((c) => c.id == customer.id).toList();
      if (matches.isNotEmpty) {
        currentCustomer = matches.first;
      }
    }

    final bool isReceivable = currentCustomer.totalBalance >= 0;

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
        title: Text(currentCustomer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: themeState.primaryColor, // 🚀 Dynamic Theme Color
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            tooltip: 'Edit Contact Details',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddCustomerDialog(
                  existingCustomer: currentCustomer,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'View & Print PDF',
            onPressed: () {
              final entries = transactionState.value ?? [];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfPreviewScreen(
                    customer: currentCustomer,
                    entries: entries,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          // 🚀 DESKTOP WIDTH FIX: 1200px for a professional ledger view
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _buildBalanceHeader(currentCustomer, isReceivable, themeState.primaryColor), // 🚀 Pass Theme Color
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20, color: themeState.primaryColor.withOpacity(0.6)),
                    const SizedBox(width: 8),
                    const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: transactionState.when(
                  loading: () => Center(child: CircularProgressIndicator(color: themeState.primaryColor)),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  data: (entries) {
                    if (entries.isEmpty) {
                      return const Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.grey, fontSize: 16)));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Dismissible(
                          key: Key(entry.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) => _showDeleteConfirmation(context),
                          onDismissed: (direction) {
                            ref.read(customerProvider.notifier).deleteEntry(entry.id, customer.id);
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
                          ),
                          child: _buildTransactionItem(context, ref, entry, themeState.primaryColor),
                        );
                      },
                    );
                  },
                ),
              ),
              _buildActionButtons(context, themeState.primaryColor), // 🚀 Pass Theme Color
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, WidgetRef ref, KhataEntryEntity entry, Color primaryColor) {
    final bool isGave = entry.type == EntryType.gave;
    final String dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(entry.date);
    final String displayNotes = (entry.notes != null && entry.notes!.isNotEmpty) ? entry.notes! : (isGave ? "Gave" : "Got");

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayNotes, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            'Rs. ${entry.amount.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isGave ? Colors.red.shade700 : Colors.green.shade700),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: primaryColor.withOpacity(0.6), size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddTransactionDialog(
                  customerId: customer.id,
                  isGave: isGave,
                  existingEntry: entry,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceHeader(CustomerEntity currentCustomer, bool isReceivable, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryColor, // 🚀 Dynamic Theme Color
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Text(isReceivable ? "You'll Get" : "You'll Give", style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'Rs. ${currentCustomer.totalBalance.abs().toStringAsFixed(0)}',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: isReceivable ? const Color(0xFF10B981) : Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(child: _actionButton(label: 'Gave (Out)', color: Colors.red.shade600, icon: Icons.remove_circle_outline, onTap: () {
            showDialog(context: context, builder: (context) => AddTransactionDialog(customerId: customer.id, isGave: true));
          })),
          const SizedBox(width: 16),
          Expanded(child: _actionButton(label: 'Got (In)', color: const Color(0xFF10B981), icon: Icons.add_circle_outline, onTap: () {
            showDialog(context: context, builder: (context) => AddTransactionDialog(customerId: customer.id, isGave: false));
          })),
        ],
      ),
    );
  }

  Widget _actionButton({required String label, required Color color, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Transaction?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove this record?'),
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