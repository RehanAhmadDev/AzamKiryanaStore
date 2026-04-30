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
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  List<dynamic> _transactions = [];
  bool _isLoading = true;

  // 🚀 FIXED: Ye variable screen ka live balance handle karega
  late double _currentBalance;

  @override
  void initState() {
    super.initState();
    // Shuru mein balance wahi hoga jo pichli screen se aaya
    _currentBalance = widget.customer.totalBalance;
    _fetchTransactions();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('khata_entries')
          .select()
          .eq('customer_id', widget.customer.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _transactions = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      final retryResponse = await _supabase
          .from('khata_entries')
          .select()
          .eq('customer_id', widget.customer.id);

      if (mounted) {
        setState(() {
          _transactions = retryResponse;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveEntry(String type) async {
    final String amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) return;

    final double amount = double.tryParse(amountStr) ?? 0.0;
    final String description = _descController.text.trim();

    try {
      // 1. Transaction Table mein entry dalein
      await _supabase.from('khata_entries').insert({
        'customer_id': widget.customer.id,
        'amount': amount,
        'type': type,
        'description': description.isEmpty
            ? (type == 'credit' ? 'Credit' : 'Payment')
            : description,
      });

      // 🚀 2. Naya balance calculate karein (Current balance mein add/sub karein)
      final double updatedBalance = type == 'credit'
          ? _currentBalance + amount
          : _currentBalance - amount;

      // 3. Customers table mein update karein
      await _supabase
          .from('customers')
          .update({'total_balance': updatedBalance})
          .eq('id', widget.customer.id);

      if (mounted) {
        // 🚀 4. UI ko foran refresh karein
        setState(() {
          _currentBalance = updatedBalance; // Balance card foran update hoga
        });

        Navigator.pop(context); // Dialog band
        _amountController.clear();
        _descController.clear();
        _fetchTransactions(); // List refresh

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry Saved Successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ... (Baaki UI functions jaise _showEntryDialog, build, etc. wahi rahengi)
  // Sirf Balance Card mein widget.customer.totalBalance ki jagah _currentBalance use karna hai.

  void _showEntryDialog(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type == 'credit' ? 'Give Credit (Udhaar)' : 'Receive Payment (Wasooli)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: type == 'credit' ? Colors.red : Colors.green),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount (Rs.)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: type == 'credit' ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _saveEntry(type),
                child: const Text('Confirm Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(widget.customer.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildBalanceCard(), // Is mein _currentBalance use ho raha hai
          _buildTransactionList(),
        ],
      ),
      bottomNavigationBar: _buildBottomActionButtons(),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const Text('Current Net Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'Rs. ${_currentBalance.abs().toStringAsFixed(0)}', // 🚀 FIXED
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _currentBalance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
          Text(
            _currentBalance >= 0 ? 'To Receive' : 'To Pay',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
          ? const Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final tx = _transactions[index];
          final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          final bool isCredit = tx['type']?.toString() == 'credit';
          final String description = tx['description']?.toString() ?? (isCredit ? 'Credit Entry' : 'Payment Received');
          final String? dateStr = tx['created_at']?.toString();
          final DateTime date = dateStr != null ? DateTime.parse(dateStr).toLocal() : DateTime.now();

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: ListTile(
              leading: Icon(isCredit ? Icons.arrow_upward : Icons.arrow_downward, color: isCredit ? Colors.red : Colors.green),
              title: Text(description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(date), style: const TextStyle(fontSize: 11)),
              trailing: Text('Rs. ${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: isCredit ? Colors.red : Colors.green)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () => _showEntryDialog('credit'),
              child: const Text('Give Credit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () => _showEntryDialog('payment'),
              child: const Text('Receive Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}