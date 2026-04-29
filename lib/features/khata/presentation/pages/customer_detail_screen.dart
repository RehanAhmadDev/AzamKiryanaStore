import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/khata_entry_entity.dart';

import '../state/state/khata_provider.dart';
import '../widgets/add_transaction_dialog.dart';


class CustomerDetailScreen extends ConsumerWidget {
  final CustomerEntity customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionProvider(customer.id));
    final bool isReceivable = customer.totalBalance >= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(customer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildBalanceHeader(isReceivable),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.history, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),

          Expanded(
            child: transactionState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(
                    child: Text('No transactions yet.', style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _buildTransactionItem(entry);
                  },
                );
              },
            ),
          ),

          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(KhataEntryEntity entry) {
    final bool isGave = entry.type == EntryType.gave;
    final String dateStr = DateFormat('dd MMM yyyy').format(entry.date);

    // Notes ka Null Check yahan lagaya hai
    final String displayNotes = (entry.notes != null && entry.notes!.isNotEmpty)
        ? entry.notes!
        : (isGave ? "Gave" : "Got");

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayNotes, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Text(
            'Rs. ${entry.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isGave ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceHeader(bool isReceivable) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Text(
            isReceivable ? "You'll Get" : "You'll Give",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Rs. ${customer.totalBalance.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: isReceivable ? const Color(0xFF10B981) : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              label: 'DIYE (Gave)',
              color: Colors.red.shade600,
              icon: Icons.remove_circle_outline,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AddTransactionDialog(
                    customerId: customer.id,
                    isGave: true,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _actionButton(
              label: 'LIYE (Got)',
              color: const Color(0xFF10B981),
              icon: Icons.add_circle_outline,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AddTransactionDialog(
                    customerId: customer.id,
                    isGave: false,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required String label, required Color color, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
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
}