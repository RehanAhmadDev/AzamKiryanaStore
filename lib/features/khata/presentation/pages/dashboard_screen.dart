// lib/features/dashboard/presentation/pages/dashboard_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'khata_screen.dart';
import '../../../pos/presentation/pages/inventory_screen.dart';
import '../../../pos/presentation/pages/invoices_receipts_screen.dart';
import '../../../khata/presentation/pages/receivables_screen.dart';
import '../../../khata/presentation/state/state/khata_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<Map<String, double>> _fetchSalesStats() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.from('sales').select('total_amount, sale_type');

      double totalCash = 0;
      double totalKhata = 0;

      for (var record in response) {
        double amount = (record['total_amount'] as num).toDouble();
        if (record['sale_type'] == 'cash') {
          totalCash += amount;
        } else {
          totalKhata += amount;
        }
      }
      return {'cash': totalCash, 'khata': totalKhata};
    } catch (e) {
      return {'cash': 0, 'khata': 0};
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerState = ref.watch(customerProvider);

    return Scaffold(
      drawer: _buildSideDrawer(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildPremiumHeader(context),
              Expanded(
                child: customerState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (customers) {
                    return FutureBuilder<Map<String, double>>(
                      future: _fetchSalesStats(),
                      builder: (context, snapshot) {
                        double cashSales = snapshot.data?['cash'] ?? 0;
                        double khataSales = snapshot.data?['khata'] ?? 0;
                        double totalCombinedSales = cashSales + khataSales;

                        // 🚀 NEW LOGIC: Wasooli vs Adayigi calculation
                        double totalToReceive = 0;
                        double totalToPay = 0;

                        for (var customer in customers) {
                          if (customer.totalBalance > 0) {
                            totalToReceive += customer.totalBalance;
                          } else if (customer.totalBalance < 0) {
                            totalToPay += customer.totalBalance.abs();
                          }
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            await ref.read(customerProvider.notifier).loadCustomers();
                          },
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20.0),
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Business Overview',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Main Sales Card
                                _buildGlassCard(
                                  title: 'Total Sales (This Month)',
                                  amount: 'Rs. ${totalCombinedSales.toStringAsFixed(0)}',
                                  icon: Icons.trending_up,
                                  color: const Color(0xFF10B981),
                                ),
                                const SizedBox(height: 16),

                                // Wasooli (Receivables) - Green
                                _buildGlassCard(
                                  title: 'Total Wasooli (To Receive)',
                                  amount: 'Rs. ${totalToReceive.toStringAsFixed(0)}',
                                  icon: Icons.call_received_rounded,
                                  color: const Color(0xFF10B981),
                                ),
                                const SizedBox(height: 16),

                                // Adayigi (Payables) - Red
                                _buildGlassCard(
                                  title: 'Total Adayigi (To Pay)',
                                  amount: 'Rs. ${totalToPay.toStringAsFixed(0)}',
                                  icon: Icons.call_made_rounded,
                                  color: const Color(0xFFEF4444),
                                ),
                                const SizedBox(height: 16),

                                // Active Customers Card
                                _buildGlassCard(
                                  title: 'Active Customers',
                                  amount: customers.length.toString(),
                                  icon: Icons.people_alt,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Modern Dark Blue
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Azam Kiryana',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                  ),
                  Text(
                    'Market Insight',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required String title, required String amount, required IconData icon, required Color color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        amount,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: color == const Color(0xFFEF4444) ? const Color(0xFFEF4444) : const Color(0xFF0F172A)
                        )
                    ),
                    Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0F172A)),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront, color: Colors.white, size: 48),
                SizedBox(height: 10),
                Text('Main Menu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          _drawerItem(
              icon: Icons.dashboard_rounded,
              title: 'Dashboard',
              onTap: () => Navigator.pop(context)
          ),
          _drawerItem(
              icon: Icons.menu_book_rounded,
              title: 'Customer Khata',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const KhataScreen()));
              }
          ),
          _drawerItem(
              icon: Icons.point_of_sale_rounded,
              title: 'New Sale (POS)',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InventoryScreen(isPosMode: true))
                );
              }
          ),
          _drawerItem(
              icon: Icons.inventory_2_rounded,
              title: 'Inventory Management',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InventoryScreen(isPosMode: false))
                );
              }
          ),
          _drawerItem(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Receivables List',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReceivablesScreen())
                );
              }
          ),
          _drawerItem(
              icon: Icons.receipt_long_rounded,
              title: 'Receipts / Invoices',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InvoicesReceiptsScreen())
                );
              }
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF64748B)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      onTap: onTap,
    );
  }
}