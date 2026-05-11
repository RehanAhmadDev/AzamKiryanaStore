// lib/features/khata/presentation/pages/customer_ledger_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🚀 Added Riverpod
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_provider.dart'; // 🚀 Theme Provider Import
import '../../domain/entities/customer_entity.dart';

class CustomerLedgerScreen extends ConsumerStatefulWidget {
  final CustomerEntity customer;
  const CustomerLedgerScreen({super.key, required this.customer});

  @override
  ConsumerState<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends ConsumerState<CustomerLedgerScreen> {
  final _supabase = Supabase.instance.client;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  List<dynamic> _transactions = [];
  bool _isLoading = true;
  late double _currentBalance;

  @override
  void initState() {
    super.initState();
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

  Future<void> _saveEntry(String type, Color primaryColor) async {
    final String amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) return;

    final double amount = double.tryParse(amountStr) ?? 0.0;
    final String description = _descController.text.trim();

    try {
      await _supabase.from('khata_entries').insert({
        'customer_id': widget.customer.id,
        'amount': amount,
        'type': type,
        'description': description.isEmpty
            ? (type == 'credit' ? 'Credit' : 'Payment')
            : description,
      });

      final double updatedBalance = type == 'credit'
          ? _currentBalance + amount
          : _currentBalance - amount;

      await _supabase
          .from('customers')
          .update({'total_balance': updatedBalance})
          .eq('id', widget.customer.id);

      if (mounted) {
        setState(() {
          _currentBalance = updatedBalance;
        });

        Navigator.pop(context);
        _amountController.clear();
        _descController.clear();
        _fetchTransactions();

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

  void _showEntryDialog(String type, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
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
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor), borderRadius: BorderRadius.circular(12)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor), borderRadius: BorderRadius.circular(12)),
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
                onPressed: () => _saveEntry(type, primaryColor),
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
    // 🚀 Theme Watch
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(widget.customer.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: themeState.primaryColor, // 🚀 Dynamic
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          // 🚀 DESKTOP WIDTH FIX: 1200px
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _buildBalanceCard(themeState.primaryColor),
              _buildTransactionList(themeState.primaryColor),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActionButtons(themeState.primaryColor),
    );
  }

  Widget _buildBalanceCard(Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: primaryColor, // 🚀 Dynamic
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const Text('Current Net Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'Rs. ${_currentBalance.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _currentBalance >= 0 ? const Color(0xFF10B981) : Colors.redAccent,
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

  Widget _buildTransactionList(Color primaryColor) {
    return Expanded(
      child: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _transactions.isEmpty
          ? const Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.grey, fontSize: 16)))
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
              hoverColor: primaryColor.withOpacity(0.05),
              leading: Icon(isCredit ? Icons.arrow_upward : Icons.arrow_downward, color: isCredit ? Colors.red : Colors.green),
              title: Text(description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(date), style: const TextStyle(fontSize: 11)),
              trailing: Text('Rs. ${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isCredit ? Colors.red : Colors.green)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActionButtons(Color primaryColor) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showEntryDialog('credit', primaryColor),
                      child: const Text('Give Credit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showEntryDialog('payment', primaryColor),
                      child: const Text('Receive Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}