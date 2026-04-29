import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../state/state/khata_provider.dart';
import '../widgets/add_customer_dialog.dart';
import 'customer_detail_screen.dart'; // Naya import add kiya

// Riverpod ka state read karne ke liye ConsumerWidget use hota hai
class KhataScreen extends ConsumerWidget {
  const KhataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Database se customers ka data yahan listen kar rahe hain
    final customerState = ref.watch(customerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customer Khata',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFFF8FAFC), // Premium light background
        child: customerState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (customers) {
            if (customers.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return _buildCustomerCard(context, customer);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // --- Popup open karne ka logic ---
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => const AddCustomerDialog(),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Customer', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // Agar database mein koi customer na ho
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Customers Found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add your first customer or vendor.',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Individual Customer List Item
  Widget _buildCustomerCard(BuildContext context, dynamic customer) {
    // Balance display logic (Positive = Lene hain, Negative = Dene hain)
    final bool isReceivable = customer.totalBalance >= 0;
    final String balanceText = 'Rs. ${customer.totalBalance.abs().toStringAsFixed(0)}';
    final Color balanceColor = isReceivable ? const Color(0xFF10B981) : Colors.red.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          radius: 25,
          child: Text(
            customer.name[0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(customer.phone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                customer.type.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              balanceText,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: balanceColor),
            ),
            Text(
              isReceivable ? 'Aap ne lene hain' : 'Aap ne dene hain',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        onTap: () {
          // --- UPDATED: Navigate to Detail Screen ---
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailScreen(customer: customer),
            ),
          );
        },
      ),
    );
  }
}