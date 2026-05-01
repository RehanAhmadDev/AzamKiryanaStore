import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/state/khata_provider.dart';
import 'customer_detail_screen.dart';

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
            return name.contains(_searchQuery.toLowerCase()) || phone.contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              // 📊 Summary Cards
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildSummaryCard(
                      title: 'Total Receivables',
                      amount: totalReceivables,
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFF0FDF4),
                      borderColor: const Color(0xFFBBF7D0),
                      icon: Icons.arrow_downward_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      title: 'Total Payables',
                      amount: totalPayables.abs(),
                      color: const Color(0xFFEF4444),
                      bgColor: const Color(0xFFFEF2F2),
                      borderColor: const Color(0xFFFECACA),
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ],
                ),
              ),

              // 🔍 Search Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              // 📋 Filtered List
              Expanded(
                child: filteredCustomers.isEmpty
                    ? const Center(child: Text('No matching records found.', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCustomers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    final bool isReceivable = customer.totalBalance > 0;
                    final Color statusColor = isReceivable ? const Color(0xFF10B981) : (customer.totalBalance < 0 ? const Color(0xFFEF4444) : Colors.grey);

                    return Container(
                      color: Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0F172A).withOpacity(0.1),
                          child: Text(customer.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ),
                        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(customer.phone, style: const TextStyle(fontSize: 12)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rs. ${customer.totalBalance.abs().toStringAsFixed(0)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 15),
                            ),
                            Text(
                              isReceivable ? 'To Receive' : (customer.totalBalance < 0 ? 'To Pay' : 'Settled'),
                              style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CustomerDetailScreen(customer: customer)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required double amount, required Color color, required Color bgColor, required Color borderColor, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
            Text('Rs. ${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}