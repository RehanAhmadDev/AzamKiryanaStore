// lib/features/inventory/presentation/pages/inventory_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../../pos/presentation/state/pos_provider.dart'; // Ensure correct path
import '../../../pos/presentation/state/cart_provider.dart'; // Ensure correct path
import '../../../pos/presentation/widgets/barcode_scanner_widget.dart'; // Ensure correct path
import '../../../pos/presentation/pages/checkout_screen.dart'; // Ensure correct path

class InventoryScreen extends ConsumerStatefulWidget {
  final bool isPosMode;

  const InventoryScreen({super.key, this.isPosMode = true});

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

  // 🚀 Helper function to refresh products
  Future<void> _refreshProducts() async {
    await ref.read(productsProvider.notifier).fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final cartList = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        // 🚀 EXPLICIT BACK BUTTON: Desktop par laazmi show karwane ke liye
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(widget.isPosMode ? 'New Sale (POS)' : 'Inventory Master',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          // 🚀 Sync button to manually refresh if needed
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            onPressed: _refreshProducts,
          ),
          if (widget.isPosMode)
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
      // 🚀 DESKTOP FIX: Center aur ConstrainedBox for a professional desktop view
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
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
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (products) {
                    final filteredProducts = products.where((p) {
                      return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                    }).toList();

                    if (products.isEmpty) {
                      return Center(
                          child: Text(widget.isPosMode
                              ? 'No products in stock.'
                              : 'No products in stock. Add your first item!',
                              style: const TextStyle(color: Colors.grey, fontSize: 16)));
                    }

                    if (filteredProducts.isEmpty) {
                      return const Center(
                        child: Text('No products match your search.',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredProducts.length,
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final bool outOfStock = product.stock <= 0;

                        Widget productCard = Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200)),
                          child: ListTile(
                            // Hover color for desktop
                            hoverColor: Colors.grey.shade50,
                            onTap: () async {
                              if (widget.isPosMode) {
                                if (!outOfStock) {
                                  _addToCart(context, ref, product);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Item is out of stock!'), backgroundColor: Colors.red),
                                  );
                                }
                              } else {
                                // 🚀 Auto-refresh after editing
                                _showProductFormDialog(context, ref, existingProduct: product);
                              }
                            },
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF0F172A).withOpacity(0.05),
                              child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF0F172A)),
                            ),
                            title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Sale: Rs. ${product.salePrice.toStringAsFixed(0)} | Stock: ${product.stock}'),
                            trailing: widget.isPosMode
                                ? (outOfStock
                                ? const Text('Out of Stock', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))
                                : IconButton(
                              icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF10B981)),
                              onPressed: () => _addToCart(context, ref, product),
                            ))
                                : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _confirmDelete(context, ref, product),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1)),
                                  onPressed: () => _showProductFormDialog(context, ref, existingProduct: product),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (!widget.isPosMode) {
                          return Dismissible(
                            key: Key(product.id.toString()),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await _confirmDelete(context, ref, product);
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete_forever, color: Colors.white, size: 32),
                            ),
                            child: productCard,
                          );
                        }

                        return productCard;
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // --- 🛒 CART SUMMARY BOTTOM BAR ---
      // 🚀 DESKTOP FIX: Bottom bar ko bhi constrain kiya hai
      bottomNavigationBar: (widget.isPosMode && cartList.isNotEmpty)
          ? Container(
        color: const Color(0xFFF1F5F9), // Background color matching scaffold
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Container(
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
                      onPressed: () async {
                        // 🚀 FIXED: Auto-Refresh after Checkout
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckoutScreen(),
                          ),
                        );
                        // Checkout band hone par data refresh karein
                        _refreshProducts();
                      },
                      icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white),
                      label: const Text('Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      )
          : null,

      // --- ➕ ADD PRODUCT FAB ---
      floatingActionButton: !widget.isPosMode
          ? FloatingActionButton.extended(
        onPressed: () => _showProductFormDialog(context, ref),
        label: const Text('Add Product',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF0F172A),
      )
          : null,
    );
  }

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref, ProductModel product) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await ref.read(productsProvider.notifier).deleteProduct(product.id);
        _refreshProducts(); // 🚀 Refresh list
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

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

  void _handleScanToCart(BuildContext context, WidgetRef ref, String scannedCode) {
    final productsState = ref.read(productsProvider);

    productsState.whenData((products) {
      try {
        final product = products.firstWhere((p) => p.barcode == scannedCode);
        if (product.stock > 0) {
          _addToCart(context, ref, product);
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found in inventory!')),
        );
      }
    });
  }

  void _showProductFormDialog(BuildContext context, WidgetRef ref, {ProductModel? existingProduct}) {
    final isEditing = existingProduct != null;

    final nameController = TextEditingController(text: isEditing ? existingProduct.name : '');
    final barcodeController = TextEditingController(text: isEditing ? existingProduct.barcode ?? '' : '');
    final purchaseController = TextEditingController(text: isEditing ? existingProduct.purchasePrice.toStringAsFixed(0) : '');
    final saleController = TextEditingController(text: isEditing ? existingProduct.salePrice.toStringAsFixed(0) : '');
    final stockController = TextEditingController(text: isEditing ? existingProduct.stock.toString() : '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            // 🚀 DESKTOP FIX: Form dialog width constrained
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEditing ? 'Edit Product' : 'New Product', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildField(nameController, 'Product Name', Icons.edit),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildField(barcodeController, 'Barcode', Icons.qr_code)),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
                                  Navigator.pop(context);
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () async {
                          if (nameController.text.isEmpty) return;

                          final newProductData = ProductModel(
                            id: isEditing ? existingProduct.id : '',
                            name: nameController.text,
                            barcode: barcodeController.text.isEmpty ? null : barcodeController.text,
                            purchasePrice: double.tryParse(purchaseController.text) ?? 0.0,
                            salePrice: double.tryParse(saleController.text) ?? 0.0,
                            stock: int.tryParse(stockController.text) ?? 0,
                          );

                          if (isEditing) {
                            await ref.read(productsProvider.notifier).updateProduct(newProductData);
                          } else {
                            await ref.read(productsProvider.notifier).addProduct(newProductData);
                          }

                          _refreshProducts(); // 🚀 Refresh list
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(isEditing ? 'Update' : 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}