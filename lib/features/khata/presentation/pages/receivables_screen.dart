// lib/features/khata/presentation/pages/receivables_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/state/khata_provider.dart';
import 'customer_ledger_screen.dart';

class ReceivablesScreen extends ConsumerStatefulWidget {
  const ReceivablesScreen({super.key});

  @override
  ConsumerState<ReceivablesScreen> createState() => _ReceivablesScreenState();
}

class _ReceivablesScreenState extends ConsumerState<ReceivablesScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Screen load hote hi latest data fetch karne ke liye
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProvider.notifier).loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Receivables & Payables',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(customerProvider.notifier).loadCustomers(),
          ),
        ],
      ),
      body: customerState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (customers) {
          double totalReceivables = 0;
          double totalPayables = 0;

          // Calculations based on totalBalance
          for (var customer in customers) {
            if (customer.totalBalance > 0) {
              totalReceivables += customer.totalBalance;
            } else if (customer.totalBalance < 0) {
              totalPayables += customer.totalBalance;
            }
          }

          final filteredCustomers = customers.where((customer) {
            final name = customer.name.toLowerCase();
            final phone = customer.phone.toLowerCase();
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || phone.contains(query);
          }).toList();

          return Column(
            children: [
              // --- 📊 TOP SUMMARY CARDS ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 24),
                            const SizedBox(height: 8),
                            const Text('Total Receivables', style: TextStyle(color: Color(0xFF475569), fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              '+ Rs. ${totalReceivables.toStringAsFixed(2)}',
                              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          border: Border.all(color: const Color(0xFFFECACA)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_upward_rounded, color: Color(0xFFEF4444), size: 24),
                            const SizedBox(height: 8),
                            const Text('Total Payables', style: TextStyle(color: Color(0xFF475569), fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              '- Rs. ${totalPayables.abs().toStringAsFixed(2)}',
                              style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- 🔍 SEARCH BAR ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // --- 📋 CUSTOMERS LIST ---
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(customerProvider.notifier).loadCustomers();
                  },
                  child: filteredCustomers.isEmpty
                      ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Text('No customers found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ),
                    ],
                  )
                      : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredCustomers.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      final String name = customer.name;
                      final String phone = customer.phone;
                      final double balance = customer.totalBalance;

                      String statusText = 'Settled';
                      Color statusColor = Colors.grey;
                      String balancePrefix = '';

                      if (balance > 0) {
                        statusText = 'To Receive';
                        statusColor = const Color(0xFF10B981);
                        balancePrefix = '+ ';
                      } else if (balance < 0) {
                        statusText = 'To Pay';
                        statusColor = const Color(0xFFEF4444);
                        balancePrefix = '- ';
                      }

                      return Container(
                        color: Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF0F172A).withOpacity(0.1),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          subtitle: Text(
                            phone,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$balancePrefix Rs. ${balance.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: statusColor.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            // 🚀 Professional Navigation with CustomerEntity
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomerLedgerScreen(customer: customer),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}