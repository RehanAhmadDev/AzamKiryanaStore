import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../state/pos_provider.dart';
import '../state/cart_provider.dart';
import '../widgets/barcode_scanner_widget.dart';
import 'checkout_screen.dart'; // Naya import Checkout Screen ke liye

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

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final cartList = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('New Sale (POS)',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Scan to Cart Button
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF10B981)),
            tooltip: 'Scan & Add to Cart',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BarcodeScannerWidget(
                    onDetect: (code) {
                      _handleScanToCart(context, ref, code);
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- 🔍 SEARCH BAR SECTION ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search product by name...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // --- 📦 PRODUCT LIST SECTION ---
          Expanded(
            child: productsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (products) {
                // Filter products based on search query
                final filteredProducts = products.where((p) {
                  return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                if (products.isEmpty) {
                  return const Center(
                      child: Text('No products in stock. Add your first item!'));
                }

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text('No products match your search.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final bool outOfStock = product.stock <= 0;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        onTap: () {
                          if (!outOfStock) {
                            _addToCart(context, ref, product);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Item is out of stock!'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0F172A).withOpacity(0.05),
                          child: const Icon(Icons.shopping_bag_outlined,
                              color: Color(0xFF0F172A)),
                        ),
                        title: Text(product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'Sale: Rs. ${product.salePrice.toStringAsFixed(0)} | Stock: ${product.stock}'),
                        trailing: outOfStock
                            ? const Text('Out of Stock', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))
                            : IconButton(
                          icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF10B981)),
                          onPressed: () => _addToCart(context, ref, product),
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

      // --- 🛒 CART SUMMARY BOTTOM BAR ---
      bottomNavigationBar: cartList.isNotEmpty
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cartList.length} Items in Cart',
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Total: Rs. ${ref.read(cartProvider.notifier).totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // --- 🛠️ FIXED: Navigating to Checkout Screen ---
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CheckoutScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white),
                label: const Text('Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      )
          : null,

      // --- ➕ ADD PRODUCT FAB ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context, ref),
        label: const Text('Add Product',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF0F172A),
      ),
    );
  }

  // --- HELPER: Add to Cart ---
  void _addToCart(BuildContext context, WidgetRef ref, ProductModel product) {
    final cartItem = CartItem(
      productId: product.id,
      name: product.name,
      price: product.salePrice,
    );
    ref.read(cartProvider.notifier).addItem(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- HELPER: Handle Scan to Cart ---
  void _handleScanToCart(BuildContext context, WidgetRef ref, String scannedCode) {
    final productsState = ref.read(productsProvider);

    productsState.whenData((products) {
      try {
        final product = products.firstWhere((p) => p.barcode == scannedCode);
        if (product.stock > 0) {
          _addToCart(context, ref, product);
          Navigator.pop(context); // Close scanner after success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scanned item is out of stock!'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found in inventory!')),
        );
      }
    });
  }

  // --- 🛠️ ADVANCED ADD PRODUCT DIALOG ---
  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final barcodeController = TextEditingController();
    final purchaseController = TextEditingController();
    final saleController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_business, color: Color(0xFF0F172A)),
              SizedBox(width: 10),
              Text('New Product', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(nameController, 'Product Name', Icons.edit),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField(barcodeController, 'Barcode', Icons.qr_code)),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
                      icon: const Icon(Icons.qr_code_scanner, size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BarcodeScannerWidget(
                              onDetect: (code) {
                                setState(() {
                                  barcodeController.text = code;
                                });
                                Navigator.pop(context); // Close scanner after reading code
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField(purchaseController, 'Purchase Price', Icons.download, isNumber: true),
                const SizedBox(height: 12),
                _buildField(saleController, 'Sale Price', Icons.sell, isNumber: true),
                const SizedBox(height: 12),
                _buildField(stockController, 'Initial Stock', Icons.inventory, isNumber: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    saleController.text.isEmpty ||
                    stockController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }

                try {
                  final newProduct = ProductModel(
                    id: '', // Supabase handles this
                    name: nameController.text,
                    barcode: barcodeController.text.isEmpty ? null : barcodeController.text,
                    purchasePrice: double.tryParse(purchaseController.text) ?? 0.0,
                    salePrice: double.tryParse(saleController.text) ?? 0.0,
                    stock: int.tryParse(stockController.text) ?? 0,
                  );

                  await ref.read(productsProvider.notifier).addProduct(newProduct);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Save Product', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // UI Helper for fields
  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}