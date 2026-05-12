// lib/features/inventory/presentation/pages/product_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../domain/entities/product_entity.dart';
import '../state/inventory_provider.dart';
import 'barcode_scanner_view.dart';

// 🚀 NAYA IMPORTS: Category data ke liye
import '../../../category/presentation/state/category_provider.dart';
import '../../../category/domain/entities/category_entity.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final ProductEntity? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  // 🚀 UPDATE: Naya variable ID save karne ke liye
  String? _selectedCategoryId;

  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _stockController;
  late TextEditingController _lowStockController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _barcodeController = TextEditingController(text: widget.product?.barcode ?? '');
    _purchasePriceController = TextEditingController(text: widget.product != null ? widget.product!.purchasePrice.toStringAsFixed(0) : '');
    _salePriceController = TextEditingController(text: widget.product != null ? widget.product!.salePrice.toStringAsFixed(0) : '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _lowStockController = TextEditingController(text: widget.product?.lowStockThreshold.toString() ?? '5');

    // 🚀 UPDATE: Edit mode mein category ID fetch karna
    _selectedCategoryId = widget.product?.categoryId;

    // Screen khulte hi naye database categories ko load karna
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).fetchCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode(Color primaryColor) async {
    final String? scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerView()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      setState(() {
        _barcodeController.text = scannedCode;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isEditMode = widget.product != null;

      final productToSave = ProductEntity(
        id: isEditMode ? widget.product!.id : const Uuid().v4(),
        name: _nameController.text.trim(),
        barcode: _barcodeController.text.trim(),
        purchasePrice: double.parse(_purchasePriceController.text.trim()),
        salePrice: double.parse(_salePriceController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        lowStockThreshold: int.parse(_lowStockController.text.trim()),
        categoryId: _selectedCategoryId, // 🚀 UPDATE: Database wali category_id
        createdAt: isEditMode ? widget.product!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      final repository = ref.read(inventoryRepositoryProvider);

      if (isEditMode) {
        await repository.updateProduct(productToSave);
      } else {
        await repository.addProduct(productToSave);
      }

      await ref.read(inventoryProvider.notifier).fetchProducts();

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final isEditMode = widget.product != null;

    // 🚀 UPDATE: Database se aayi hui categories ko watch karna
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: themeState.primaryColor,
        elevation: 0,
        title: Text(isEditMode ? 'Edit Product' : 'Add New Item',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: themeState.primaryColor))
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: themeState.primaryColor,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionTitle('Basic Information'),
                        _buildCard([
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _barcodeController,
                                  label: 'Barcode Number',
                                  icon: Icons.qr_code_2_rounded,
                                  keyboardType: TextInputType.text,
                                  isRequired: false,
                                  primaryColor: themeState.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => _scanBarcode(themeState.primaryColor),
                                child: Container(
                                  height: 55,
                                  width: 55,
                                  decoration: BoxDecoration(
                                    color: themeState.primaryColor,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Product Name',
                            icon: Icons.shopping_bag_rounded,
                            keyboardType: TextInputType.name,
                            primaryColor: themeState.primaryColor,
                          ),
                          const SizedBox(height: 16),

                          // 🚀 UPDATE: Naya dynamic dropdown menu function call
                          _buildCategoryDropdown(themeState.primaryColor, categories),
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionTitle('Pricing Details'),
                        _buildCard([
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _purchasePriceController,
                                  label: 'Purchase Price',
                                  icon: Icons.south_east_rounded,
                                  keyboardType: TextInputType.number,
                                  prefixText: 'Rs. ',
                                  primaryColor: themeState.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _salePriceController,
                                  label: 'Sale Price',
                                  icon: Icons.north_east_rounded,
                                  keyboardType: TextInputType.number,
                                  prefixText: 'Rs. ',
                                  primaryColor: themeState.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionTitle('Inventory Tracking'),
                        _buildCard([
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _stockController,
                                  label: 'Initial Stock',
                                  icon: Icons.inventory_2_rounded,
                                  keyboardType: TextInputType.number,
                                  primaryColor: themeState.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _lowStockController,
                                  label: 'Low Stock Alert',
                                  icon: Icons.notification_important_rounded,
                                  keyboardType: TextInputType.number,
                                  primaryColor: themeState.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ]),

                        const SizedBox(height: 40),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: themeState.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 4,
                          ),
                          onPressed: _saveProduct,
                          child: const Text('Save To Inventory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  // 🚀 UPDATE: Naya dropdown menu jo database se data leta hai
  Widget _buildCategoryDropdown(Color primaryColor, List<CategoryEntity> categories) {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      decoration: InputDecoration(
        labelText: 'Category (Optional)',
        labelStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
        prefixIcon: Icon(Icons.category_rounded, color: primaryColor.withOpacity(0.6)),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      items: categories.map((cat) {
        return DropdownMenuItem<String>(
          value: cat.id,
          child: Text(cat.name),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedCategoryId = val),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required Color primaryColor,
    String? prefixText,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
        prefixText: prefixText,
        prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.6), size: 20),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primaryColor, width: 1.5)),
      ),
      validator: isRequired ? (val) => (val == null || val.trim().isEmpty) ? 'Required' : null : null,
    );
  }
}