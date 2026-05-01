import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🚀 Added Riverpod
import '../../domain/entities/product_entity.dart';
import '../state/inventory_provider.dart'; // 🚀 Added Provider Import
import 'product_form_screen.dart';
import 'barcode_scanner_view.dart';

// 🚀 Changed to ConsumerStatefulWidget
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🚀 Helper to calculate stats dynamically
  Map<String, dynamic> _calculateAnalytics(List<ProductEntity> products) {
    double stockValue = 0;
    double potentialProfit = 0;
    int lowStock = 0;

    for (var p in products) {
      stockValue += (p.purchasePrice * p.stock);
      potentialProfit += ((p.salePrice - p.purchasePrice) * p.stock);
      if (p.isLowStock) lowStock++;
    }
    return {'value': stockValue, 'profit': potentialProfit, 'low': lowStock};
  }

  Future<void> _onScanPressed() async {
    final String? scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerView()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      setState(() {
        _searchController.text = scannedCode;
        _searchQuery = scannedCode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 Riverpod se real-time data watch kar rahe hain
    final allProducts = ref.watch(inventoryProvider);

    // Filtering logic
    final filteredProducts = allProducts.where((product) {
      final query = _searchQuery.toLowerCase();
      final nameMatch = product.name.toLowerCase().contains(query);
      final barcodeMatch = product.barcode?.toLowerCase().contains(query) ?? false;
      return nameMatch || barcodeMatch;
    }).toList();

    // Stats calculations
    final stats = _calculateAnalytics(allProducts);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Inventory Master', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
              ref.read(inventoryProvider.notifier).fetchProducts(); // 🚀 Refresh logic
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Modern Search Header with Scanner
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _onScanPressed,
                  child: Container(
                    height: 50, width: 50,
                    decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          if (allProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatChip('Stock Value', 'Rs. ${stats['value'].toStringAsFixed(0)}', const Color(0xFF6366F1), Icons.account_balance_wallet_rounded),
                    const SizedBox(width: 12),
                    _buildStatChip('Potential Profit', 'Rs. ${stats['profit'].toStringAsFixed(0)}', const Color(0xFF10B981), Icons.trending_up_rounded),
                    const SizedBox(width: 12),
                    _buildStatChip('Low Stock Items', '${stats['low']} Items', const Color(0xFFEF4444), Icons.warning_amber_rounded),
                  ],
                ),
              ),
            ),

          Expanded(
            child: allProducts.isEmpty && _searchQuery.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
                : filteredProducts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                // 🚀 NEW: Swipe to Delete Logic
                return Dismissible(
                  key: Key(product.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) => _showDeleteConfirmation(context, product.name),
                  onDismissed: (direction) {
                    ref.read(inventoryProvider.notifier).deleteProduct(product.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${product.name} removed from inventory'), backgroundColor: Colors.red),
                    );
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.delete_forever, color: Colors.white, size: 30),
                  ),
                  child: _buildProductCard(product),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductFormScreen()));
          // Riverpod automatically updates UI, no need for manual _loadProducts()
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductEntity product) {
    final bool isLow = product.isLowStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(border: Border(left: BorderSide(color: isLow ? Colors.redAccent : const Color(0xFF10B981), width: 6))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text('Category: ${product.category ?? "General"}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildPriceInfo('Buy', product.purchasePrice),
                          const SizedBox(width: 15),
                          _buildPriceInfo('Sell', product.salePrice),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStockBadge(product.stock, isLow),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent, size: 28),
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => ProductFormScreen(product: product)));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo(String label, double price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text('Rs. ${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
      ],
    );
  }

  Widget _buildStockBadge(int stock, bool isLow) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: isLow ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isLow ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, size: 14, color: isLow ? Colors.red : Colors.green),
          const SizedBox(width: 4),
          Text('$stock Left', style: TextStyle(color: isLow ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No items found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  // 🚀 NEW: Confirmation Dialog
  Future<bool?> _showDeleteConfirmation(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to remove "$name" from inventory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}