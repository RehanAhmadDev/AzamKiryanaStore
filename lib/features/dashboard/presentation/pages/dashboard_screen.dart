// lib/features/dashboard/presentation/pages/dashboard_screen.dart

import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:async/async.dart'; // Ensure this is in pubspec.yaml

import '../../../khata/presentation/pages/khata_screen.dart';
import '../../../pos/presentation/pages/inventory_screen.dart';
import '../../../pos/presentation/pages/invoices_receipts_screen.dart';
import '../../../khata/presentation/pages/receivables_screen.dart';
import '../../../khata/presentation/state/state/khata_provider.dart';

// Inventory aur Provider imports
import '../../../inventory/presentation/screens/inventory_screen.dart' as stock;
import '../../../inventory/presentation/state/inventory_provider.dart';

// Expense Screen Import
import '../../../expenses/presentation/pages/add_expense_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  // 🚀 HIGHLY REACTIVE: Combined Real-time Stream
  Stream<Map<String, double>> _businessStatsStream() {
    final client = Supabase.instance.client;

    // Monitor both tables for ANY change (Insert/Update/Delete)
    final salesStream = client.from('sales').stream(primaryKey: ['id']);
    final expensesStream = client.from('expenses').stream(primaryKey: ['id']);

    // Merge signals from both streams
    return StreamGroup.merge([salesStream, expensesStream]).asyncMap((_) async {
      // Re-fetch fresh data from both tables when either signals a change
      final salesData = await client.from('sales').select();
      final expensesData = await client.from('expenses').select();

      double totalCash = 0;
      double totalKhata = 0;
      double grossProfit = 0;
      double totalExpenses = 0;

      for (var record in salesData) {
        double amount = (record['total_amount'] as num).toDouble();
        double profit = (record['total_profit'] as num? ?? 0).toDouble();
        grossProfit += profit;

        if (record['sale_type'] == 'cash') {
          totalCash += amount;
        } else {
          totalKhata += amount;
        }
      }

      for (var expense in expensesData) {
        totalExpenses += (expense['amount'] as num).toDouble();
      }

      return {
        'cash': totalCash,
        'khata': totalKhata,
        'grossProfit': grossProfit,
        'expenses': totalExpenses,
        'netProfit': grossProfit - totalExpenses,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    final lowStockItems = ref.watch(inventoryProvider.notifier).getLowStockItems(threshold: 5);

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
                    return StreamBuilder<Map<String, double>>(
                      // ✨ UniqueKey forces refresh when data emits
                      key: UniqueKey(),
                      stream: _businessStatsStream(),
                      builder: (context, snapshot) {
                        final stats = snapshot.data ?? {};
                        double cashSales = stats['cash'] ?? 0;
                        double khataSales = stats['khata'] ?? 0;
                        double totalExpenses = stats['expenses'] ?? 0;
                        double netProfit = stats['netProfit'] ?? 0;
                        double totalCombinedSales = cashSales + khataSales;

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
                            await ref.read(inventoryProvider.notifier).fetchProducts();
                          },
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20.0),
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (lowStockItems.isNotEmpty) ...[
                                  _buildLowStockAlert(lowStockItems),
                                  const SizedBox(height: 24),
                                ],

                                const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildActionCard(
                                      context,
                                      title: 'Inventory',
                                      icon: Icons.inventory_2_rounded,
                                      color: const Color(0xFF6366F1),
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const stock.InventoryScreen())),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildActionCard(
                                      context,
                                      title: 'New Sale',
                                      icon: Icons.point_of_sale_rounded,
                                      color: const Color(0xFF10B981),
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen(isPosMode: true))),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildActionCard(
                                      context,
                                      title: 'Expense',
                                      icon: Icons.account_balance_wallet_rounded,
                                      color: const Color(0xFFEF4444),
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddExpenseScreen())),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                const Text('Business Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                const SizedBox(height: 16),

                                _buildGlassCard(
                                  title: 'Net Profit (After Expenses)',
                                  amount: 'Rs. ${netProfit.toStringAsFixed(0)}',
                                  icon: Icons.auto_graph_rounded,
                                  color: const Color(0xFF8B5CF6),
                                ),
                                const SizedBox(height: 16),

                                _buildGlassCard(
                                  title: 'Total Expenses',
                                  amount: 'Rs. ${totalExpenses.toStringAsFixed(0)}',
                                  icon: Icons.money_off_rounded,
                                  color: const Color(0xFFEF4444),
                                ),
                                const SizedBox(height: 16),

                                _buildGlassCard(
                                  title: 'Total Sales',
                                  amount: 'Rs. ${totalCombinedSales.toStringAsFixed(0)}',
                                  icon: Icons.trending_up,
                                  color: const Color(0xFF6366F1),
                                ),
                                const SizedBox(height: 16),
                                _buildGlassCard(
                                  title: 'Total Wasooli',
                                  amount: 'Rs. ${totalToReceive.toStringAsFixed(0)}',
                                  icon: Icons.call_received_rounded,
                                  color: const Color(0xFF10B981),
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

  // UI Helper Widgets (Original Logic Maintained)
  Widget _buildLowStockAlert(List<dynamic> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
              const SizedBox(width: 8),
              const Text('Low Stock Alert!', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
              const Spacer(),
              Text('${items.length} items', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ...items.take(2).map((item) => Text('• ${item.name} (${item.stock} left)', style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D)))),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              FittedBox(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
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
              Text('Azam Kiryana', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
              Text('Market Insight', style: TextStyle(fontSize: 13, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required String title, required String amount, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(amount, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSideDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF0F172A)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront, color: Colors.white, size: 40),
                SizedBox(height: 10),
                Text('Main Menu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          _drawerItem(icon: Icons.dashboard_rounded, title: 'Dashboard', onTap: () => Navigator.pop(context)),
          _drawerItem(icon: Icons.menu_book_rounded, title: 'Customer Khata', onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const KhataScreen()));
          }),
          _drawerItem(icon: Icons.inventory_2_rounded, title: 'Inventory Management', onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const stock.InventoryScreen()));
          }),
          _drawerItem(icon: Icons.call_received_rounded, title: 'Receivables (Wasooli)', onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceivablesScreen()));
          }),
          _drawerItem(icon: Icons.receipt_long_rounded, title: 'Invoices & Receipts', onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const InvoicesReceiptsScreen()));
          }),
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