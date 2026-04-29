import 'dart:ui';
import 'package:flutter/material.dart';
import 'khata_screen.dart';
// --- Naya Import ---
import '../../../pos/presentation/pages/inventory_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
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
                      _buildGlassCard(
                        title: 'Total Sales',
                        amount: 'Rs. 580',
                        icon: Icons.trending_up,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 16),
                      _buildGlassCard(
                        title: 'Total Income',
                        amount: 'Rs. 580',
                        icon: Icons.account_balance_wallet,
                        color: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(height: 16),
                      _buildGlassCard(
                        title: 'Active Customers',
                        amount: '2',
                        icon: Icons.people_alt,
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
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
        color: Theme.of(context).colorScheme.primary,
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
                    'Store POS',
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
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(amount, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                ],
              ),
              Icon(icon, color: color, size: 32),
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
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: const Center(
              child: Icon(Icons.storefront, color: Colors.white, size: 48),
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

          // --- 🛠️ YAHAN LAGA HAI ASAL LISTENER POS PAR ---
          _drawerItem(
              icon: Icons.point_of_sale_rounded,
              title: 'New Sale (POS)',
              onTap: () {
                Navigator.pop(context); // Drawer band karein
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InventoryScreen())
                );
              }
          ),

          _drawerItem(
              icon: Icons.inventory_2_rounded,
              title: 'Inventory Management',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen()));
              }
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF64748B)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}