// lib/features/khata/presentation/pages/customer_ledger_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerLedgerScreen extends StatefulWidget {
  final CustomerEntity customer;
  const CustomerLedgerScreen({super.key, required this.customer});

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 🚀 FIX: Agar database mein 'created_at' ka masla hai, toh order hatane se error theek ho jayega
      final response = await _supabase
          .from('khata_entries')
          .select()
          .eq('customer_id', widget.customer.id);
      // .order('created_at', ascending: false); // Temporary commented to fix PostgrestException

      if (mounted) {
        setState(() {
          _transactions = response;
        });
      }
    } catch (e) {
      if (mounted) {
        // Error handling for missing columns or connection issues
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database Error: Please check column names in Supabase.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
            widget.customer.name,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // --- 📊 TOP SUMMARY CARD ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Text('Current Net Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  'Rs. ${widget.customer.totalBalance.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: widget.customer.totalBalance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
                Text(
                  widget.customer.totalBalance >= 0 ? 'To Receive' : 'To Pay',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // --- 📋 TRANSACTIONS LIST ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : _transactions.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No transactions yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                final double amount = (tx['amount'] as num).toDouble();
                final bool isCredit = tx['type'] == 'credit';

                // Handling potentially missing created_at in the data map
                final dateStr = tx['created_at'] ?? DateTime.now().toIso8601String();
                final date = DateTime.parse(dateStr).toLocal();

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCredit ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                      child: Icon(
                        isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isCredit ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      tx['description'] ?? (isCredit ? 'Credit Entry' : 'Payment Received'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(date),
                        style: const TextStyle(fontSize: 11)
                    ),
                    trailing: Text(
                      'Rs. ${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isCredit ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // TODO: Functionality to add credit entry
                },
                child: const Text('Give Credit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // TODO: Functionality to add payment entry
                },
                child: const Text('Receive Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}