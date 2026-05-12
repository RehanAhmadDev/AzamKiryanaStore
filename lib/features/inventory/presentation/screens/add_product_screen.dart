// lib/features/inventory/presentation/screens/add_product_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../domain/entities/product_entity.dart';
import '../state/inventory_provider.dart';
import '../../../category/presentation/state/category_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final ProductEntity? product; // Edit mode ke liye

  const AddProductScreen({super.key, this.product});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _stockController;
  late TextEditingController _thresholdController;

  String? _selectedCategoryId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _purchasePriceController = TextEditingController(text: p?.purchasePrice.toString() ?? '');
    _salePriceController = TextEditingController(text: p?.salePrice.toString() ?? '');
    _stockController = TextEditingController(text: p?.stock.toString() ?? '');
    _thresholdController = TextEditingController(text: p?.lowStockThreshold.toString() ?? '5');
    _selectedCategoryId = p?.categoryId;
    _isActive = p?.isActive ?? true;

    // Screen khulte hi categories ko background mein fetch karna
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
    _thresholdController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final newProduct = ProductEntity(
        id: widget.product?.id ?? '', // Naye product ke liye empty
        name: _nameController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
        salePrice: double.tryParse(_salePriceController.text) ?? 0.0,
        stock: int.tryParse(_stockController.text) ?? 0,
        categoryId: _selectedCategoryId, // 🚀 Naya Category ID
        lowStockThreshold: int.tryParse(_thresholdController.text) ?? 5,
        isActive: _isActive,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.product == null) {
        ref.read(inventoryProvider.notifier).addProduct(newProduct);
      } else {
        ref.read(inventoryProvider.notifier).updateProduct(newProduct);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: themeState.primaryColor,
        title: Text(widget.product == null ? 'Add New Product' : 'Edit Product', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Basic Information', themeState.primaryColor),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Product Name *',
                    icon: Icons.inventory_2_outlined,
                    validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // 🚀 CATEGORY DROPDOWN MENU
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Category (Optional)',
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _barcodeController,
                    label: 'Barcode (Optional)',
                    icon: Icons.qr_code_scanner_rounded,
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Pricing & Stock', themeState.primaryColor),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _purchasePriceController,
                          label: 'Purchase Price *',
                          icon: Icons.money_off_rounded,
                          keyboardType: TextInputType.number,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _salePriceController,
                          label: 'Sale Price *',
                          icon: Icons.attach_money_rounded,
                          keyboardType: TextInputType.number,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _stockController,
                          label: 'Current Stock *',
                          icon: Icons.layers_outlined,
                          keyboardType: TextInputType.number,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _thresholdController,
                          label: 'Low Stock Alert At',
                          icon: Icons.warning_amber_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeState.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _saveProduct,
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: const Text('Save Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}