// lib/features/inventory/presentation/pages/inventory_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';

import '../../data/models/product_model.dart';
import '../../../pos/presentation/state/pos_provider.dart';
import '../../../pos/presentation/state/cart_provider.dart';
import '../../../pos/presentation/widgets/barcode_scanner_widget.dart';
import '../../../pos/presentation/pages/checkout_screen.dart';

// 🚀 NAYA IMPORT: Category Filter ke liye
import '../../../category/presentation/state/category_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  final bool isPosMode;

  const InventoryScreen({super.key, this.isPosMode = true});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 🚀 NAYA VARIABLE: Category filter ko track karne ke liye
  String _selectedCategoryId = 'All';

  @override
  void initState() {
    super.initState();
    // Screen khulte hi categories ko load karna
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshProducts() async {
    await ref.read(productsProvider.notifier).fetchProducts();
    await ref.read(categoryProvider.notifier).fetchCategories(); // Categories bhi refresh karein
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final productsState = ref.watch(productsProvider);
    final cartList = ref.watch(cartProvider);

    // 🚀 Categories ko watch karein
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
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
        backgroundColor: themeState.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            onPressed: _refreshProducts,
          ),
          if (widget.isPosMode)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF10B981)),
              tooltip: 'Scan & Add to Cart',
              onPressed: () => _handleOpenScanner(context),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search product by name...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
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

              // 🚀 NAYA UI: Category Filter Buttons (Chips)
              if (categories.isNotEmpty)
                Container(
                  height: 50,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length + 1, // +1 for 'All Items'
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final category = isAll ? null : categories[index - 1];
                      final isSelected = isAll ? _selectedCategoryId == 'All' : _selectedCategoryId == category!.id;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(isAll ? 'All Items' : category!.name),
                          selected: isSelected,
                          selectedColor: themeState.primaryColor,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? themeState.primaryColor : Colors.grey.shade300,
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId = isAll ? 'All' : category!.id;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

              // Product List
              Expanded(
                child: productsState.when(
                  loading: () => Center(child: CircularProgressIndicator(color: themeState.primaryColor)),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (products) {

                    // 🚀 LOGIC UPDATE: Search aur Category dono se filter karna
                    final filteredProducts = products.where((p) {
                      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                      final matchesCategory = _selectedCategoryId == 'All' || p.categoryId == _selectedCategoryId;

                      return matchesSearch && matchesCategory;
                    }).toList();

                    if (products.isEmpty) {
                      return const Center(child: Text('No products in stock.', style: TextStyle(color: Colors.grey, fontSize: 16)));
                    }

                    if (filteredProducts.isEmpty) {
                      return const Center(child: Text('No products found in this category.', style: TextStyle(color: Colors.grey, fontSize: 16)));
                    }

                    return ListView.builder(
                      itemCount: filteredProducts.length,
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final bool outOfStock = product.stock <= 0;

                        return _buildProductCard(product, themeState.primaryColor, outOfStock);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (widget.isPosMode && cartList.isNotEmpty) ? _buildCartBottomBar(themeState.primaryColor, cartList) : null,
      floatingActionButton: !widget.isPosMode
          ? FloatingActionButton.extended(
        onPressed: () => _showProductFormDialog(context, ref, themeState.primaryColor),
        label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: themeState.primaryColor,
      )
          : null,
    );
  }

  Widget _buildProductCard(ProductModel product, Color primaryColor, bool outOfStock) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        hoverColor: primaryColor.withOpacity(0.05),
        onTap: () {
          if (widget.isPosMode) {
            if (!outOfStock) _addToCart(context, ref, product);
          } else {
            _showProductFormDialog(context, ref, primaryColor, existingProduct: product);
          }
        },
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Icon(Icons.shopping_bag_outlined, color: primaryColor),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Sale: Rs. ${product.salePrice.toStringAsFixed(0)} | Stock: ${product.stock}'),
        trailing: widget.isPosMode
            ? (outOfStock
            ? const Text('Out of Stock', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))
            : Icon(Icons.add_shopping_cart, color: primaryColor))
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDelete(context, ref, product)),
            IconButton(icon: Icon(Icons.edit_outlined, color: primaryColor), onPressed: () => _showProductFormDialog(context, ref, primaryColor, existingProduct: product)),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBottomBar(Color primaryColor, List cartList) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${cartList.length} Items in Cart', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('Total: Rs. ${ref.read(cartProvider.notifier).totalPrice.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primaryColor)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutScreen()));
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
    );
  }

  // --- Functions ---

  void _handleOpenScanner(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => BarcodeScannerWidget(onDetect: (code) => _handleScanToCart(context, ref, code))));
  }

  void _addToCart(BuildContext context, WidgetRef ref, ProductModel product) {
    ref.read(cartProvider.notifier).addItem(CartItem(productId: product.id, name: product.name, price: product.salePrice));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} added to cart'), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating));
  }

  void _handleScanToCart(BuildContext context, WidgetRef ref, String scannedCode) {
    ref.read(productsProvider).whenData((products) {
      try {
        final product = products.firstWhere((p) => p.barcode == scannedCode);
        if (product.stock > 0) {
          _addToCart(context, ref, product);
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product not found!')));
      }
    });
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
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (result == true) {
      await ref.read(productsProvider.notifier).deleteProduct(product.id);
      _refreshProducts();
      return true;
    }
    return false;
  }

  void _showProductFormDialog(BuildContext context, WidgetRef ref, Color primaryColor, {ProductModel? existingProduct}) {
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
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isEditing ? 'Edit Product' : 'New Product', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildField(nameController, 'Product Name', Icons.edit),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildField(barcodeController, 'Barcode', Icons.qr_code)),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                style: IconButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                icon: const Icon(Icons.qr_code_scanner, size: 20),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => BarcodeScannerWidget(onDetect: (code) {
                                    setState(() => barcodeController.text = code);
                                    Navigator.pop(context);
                                  })));
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
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () async {
                          if (nameController.text.isEmpty) return;

                          // 🚀 UPDATE: Missing fields (createdAt, updatedAt, categoryId) fix
                          final newProduct = ProductModel(
                            id: isEditing ? existingProduct.id : '',
                            name: nameController.text,
                            barcode: barcodeController.text.isEmpty ? null : barcodeController.text,
                            purchasePrice: double.tryParse(purchaseController.text) ?? 0.0,
                            salePrice: double.tryParse(saleController.text) ?? 0.0,
                            stock: int.tryParse(stockController.text) ?? 0,
                            categoryId: isEditing ? existingProduct.categoryId : null,
                            createdAt: isEditing ? existingProduct.createdAt : DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          if (isEditing) {
                            await ref.read(productsProvider.notifier).updateProduct(newProduct);
                          } else {
                            await ref.read(productsProvider.notifier).addProduct(newProduct);
                          }

                          _refreshProducts();
                          Navigator.pop(context);
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}