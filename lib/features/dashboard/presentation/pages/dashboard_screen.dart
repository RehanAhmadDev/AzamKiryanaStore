// lib/features/dashboard/presentation/pages/dashboard_screen.dart

import 'dart:ui';
import 'dart:async';
import 'package:azam_kiryana_store/features/dashboard/presentation/pages/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../khata/presentation/pages/khata_screen.dart';
import '../../../pos/presentation/pages/inventory_screen.dart';
import '../../../pos/presentation/pages/invoices_receipts_screen.dart';
import '../../../khata/presentation/pages/receivables_screen.dart';
import '../../../khata/presentation/state/state/khata_provider.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart' as stock;
import '../../../inventory/presentation/screens/low_stock_screen.dart';
import '../../../inventory/presentation/state/inventory_provider.dart';
import '../../../expenses/presentation/pages/add_expense_screen.dart';
import '../../../expenses/presentation/pages/expense_list_screen.dart';
import '../../../category/presentation/screens/category_screen.dart';
import '../state/business_provider.dart';
import 'business_reports_screen.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  Stream<Map<String, double>> _businessStatsStream() {
    final client = Supabase.instance.client;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

    return client
        .from('sales')
        .stream(primaryKey: ['id'])
        .asyncMap((_) async {
      final salesData = await client
          .from('sales')
          .select()
          .gte('created_at', todayStart);

      final expensesData = await client
          .from('expenses')
          .select()
          .gte('date', todayStart);

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
        'todaySales': totalCash + totalKhata,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final customerState = ref.watch(customerProvider);
    final lowStockItems = ref.watch(inventoryProvider.notifier).getLowStockItems(threshold: 10);

    // 🚀 NAYA: Settings watch karein
    final business = ref.watch(businessProvider);

    return Scaffold(
      drawer: _buildSideDrawer(context, ref, business.storeName), // Store Name pass kiya
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
              _buildPremiumHeader(context, themeState.primaryColor, business.storeName), // Store Name pass kiya
              Expanded(
                child: customerState.when(
                  loading: () => Center(child: CircularProgressIndicator(color: themeState.primaryColor)),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (customers) {
                    return StreamBuilder<Map<String, double>>(
                      stream: _businessStatsStream(),
                      builder: (context, snapshot) {
                        final stats = snapshot.data ?? {};

                        double todaySales = stats['todaySales'] ?? 0;
                        double netProfit = stats['netProfit'] ?? 0;
                        double totalExpenses = stats['expenses'] ?? 0;

                        double totalToReceive = customers.fold(0, (sum, c) => sum + (c.totalBalance > 0 ? c.totalBalance : 0));

                        return RefreshIndicator(
                          onRefresh: () async {
                            await ref.read(customerProvider.notifier).loadCustomers();
                            await ref.read(inventoryProvider.notifier).fetchProducts();
                            await ref.read(businessProvider.notifier).loadSettings(); // Settings reload
                          },
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20.0),
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (lowStockItems.isNotEmpty) ...[
                                  _buildLowStockAlert(lowStockItems, context),
                                  const SizedBox(height: 24),
                                ],

                                Text("Today's Performance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeState.primaryColor)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildSummaryMiniCard('Sales', 'Rs. ${todaySales.toStringAsFixed(0)}', Colors.blue),
                                    const SizedBox(width: 12),
                                    _buildSummaryMiniCard('Profit', 'Rs. ${netProfit.toStringAsFixed(0)}', Colors.green),
                                  ],
                                ),

                                const SizedBox(height: 32),
                                Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeState.primaryColor)),
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
                                Text('Financial Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeState.primaryColor)),
                                const SizedBox(height: 16),

                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BusinessReportsScreen())),
                                  child: _buildGlassCard(
                                    title: 'Total Net Profit',
                                    amount: 'Rs. ${netProfit.toStringAsFixed(0)}',
                                    icon: Icons.auto_graph_rounded,
                                    color: const Color(0xFF8B5CF6),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildGlassCard(
                                  title: 'Total Today Expenses',
                                  amount: 'Rs. ${totalExpenses.toStringAsFixed(0)}',
                                  icon: Icons.money_off_rounded,
                                  color: const Color(0xFFEF4444),
                                ),
                                const SizedBox(height: 16),
                                _buildGlassCard(
                                  title: 'Total Outstanding Wasooli',
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

  // --- UI COMPONENTS ---

  Widget _buildSummaryMiniCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockAlert(List<dynamic> items, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LowStockScreen())),
      child: Container(
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
                const Text('View List →', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            ...items.take(2).map((item) => Text('• ${item.name} (${item.stock} left)', style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D)))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
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
                FittedBox(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🚀 FIXED: Dynamic Name Header
  Widget _buildPremiumHeader(BuildContext context, Color headerColor, String storeName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
              const Text('Smart Dashboard', style: TextStyle(fontSize: 13, color: Colors.white70)),
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

  // --- DRAWER ---

  Widget _buildSideDrawer(BuildContext context, WidgetRef ref, String storeName) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: ref.watch(themeProvider).primaryColor),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.storefront, color: Colors.white, size: 40),
                      const SizedBox(height: 10),
                      Text(storeName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                _drawerItem(icon: Icons.category_rounded, title: 'Category Management', onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryScreen()));
                }),
                _drawerItem(icon: Icons.analytics_rounded, title: 'Business Reports', onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BusinessReportsScreen()));
                }),
                _drawerItem(icon: Icons.history_rounded, title: 'Expense History', onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpenseListScreen()));
                }),
                _drawerItem(icon: Icons.receipt_long_rounded, title: 'Invoices & Receipts', onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const InvoicesReceiptsScreen()));
                }),

                // 🚀 NAYA: Settings Button
                _drawerItem(icon: Icons.settings_rounded, title: 'Business Settings', onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                }),

                _buildThemeSelector(context, ref),
              ],
            ),
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

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const Text("App Appearance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemCount: appThemes.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => ref.read(themeProvider.notifier).changeColor(appThemes[index]),
                  child: CircleAvatar(
                    backgroundColor: appThemes[index],
                    radius: 15,
                    child: themeState.primaryColor == appThemes[index]
                        ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}