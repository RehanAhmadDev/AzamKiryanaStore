import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../domain/entities/product_entity.dart';
import '../state/inventory_provider.dart';
import 'product_form_screen.dart';
import 'barcode_scanner_view.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

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
    final themeState = ref.watch(themeProvider);
    final allProducts = ref.watch(inventoryProvider);

    final filteredProducts = allProducts.where((product) {
      final query = _searchQuery.toLowerCase();
      final nameMatch = product.name.toLowerCase().contains(query);
      final barcodeMatch = product.barcode?.toLowerCase().contains(query) ?? false;
      return nameMatch || barcodeMatch;
    }).toList();

    final stats = _calculateAnalytics(allProducts);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: themeState.primaryColor, // 🚀 Theme Sync
        title: const Text('Inventory Master', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
              ref.read(inventoryProvider.notifier).fetchProducts();
            },
          ),
        ],
      ),
      body: Center( // 🚀 Centered for Desktop
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200), // 🚀 Professional Wide Width
          child: Column(
            children: [
              // Search Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                decoration: BoxDecoration(
                  color: themeState.primaryColor, // 🚀 Theme Sync
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
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
                            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
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

              // Stats Chips
              if (allProducts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
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

              // Product List
              Expanded(
                child: allProducts.isEmpty && _searchQuery.isEmpty
                    ? Center(child: CircularProgressIndicator(color: themeState.primaryColor))
                    : filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Dismissible(
                      key: Key(product.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) => _showDeleteConfirmation(context, product.name),
                      onDismissed: (direction) {
                        ref.read(inventoryProvider.notifier).deleteProduct(product.id);
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.delete_forever, color: Colors.white, size: 30),
                      ),
                      child: _buildProductCard(product, themeState.primaryColor),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: themeState.primaryColor, // 🚀 Theme Sync
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductFormScreen()));
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductEntity product, Color themeColor) {
    final bool isLow = product.isLowStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        hoverColor: themeColor.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isLow ? Colors.red.shade100 : Colors.transparent),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Rs. ${product.salePrice.toStringAsFixed(0)} | Stock: ${product.stock}',
                style: const TextStyle(color: Color(0xFF64748B))),
            if (isLow)
              const Text('⚠️ Low Stock!', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit_note_rounded, color: themeColor),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductFormScreen(product: product))),
        ),
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
          const Text('No items found', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to remove "$name"?'),
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