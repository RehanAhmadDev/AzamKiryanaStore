import 'package:flutter/material.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerDetailScreen extends StatelessWidget {
  final CustomerEntity customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
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
          // Top Balance Card
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

          // Transactions List (Abhi ke liye empty state)
          const Expanded(
            child: Center(
              child: Text('No transactions yet.', style: TextStyle(color: Colors.grey)),
            ),
          ),

          // Bottom Action Buttons (DIVE / LIYE)
          _buildActionButtons(context),
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
            isReceivable ? 'Aap ne lene hain' : 'Aap ne dene hain',
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
          // DIVE (Gave) Button
          Expanded(
            child: _actionButton(
              label: 'DIVE (Gave)',
              color: Colors.red.shade600,
              icon: Icons.remove_circle_outline,
              onTap: () {
                // TODO: Open Add Transaction Dialog (Type: Gave)
              },
            ),
          ),
          const SizedBox(width: 16),
          // LIYE (Got) Button
          Expanded(
            child: _actionButton(
              label: 'LIYE (Got)',
              color: const Color(0xFF10B981),
              icon: Icons.add_circle_outline,
              onTap: () {
                // TODO: Open Add Transaction Dialog (Type: Got)
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