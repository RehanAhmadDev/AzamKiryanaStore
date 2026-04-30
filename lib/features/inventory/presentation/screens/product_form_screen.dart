// lib/features/inventory/presentation/screens/product_form_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/product_entity.dart';
import '../../data/repositories/inventory_repository_impl.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductEntity? product;

  const ProductFormScreen({Key? key, this.product}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = InventoryRepositoryImpl(Supabase.instance.client);

  bool _isLoading = false;
  String _selectedCategory = 'Grocery'; // Default category

  final List<String> _categories = ['Grocery', 'Drinks', 'Snacks', 'Bakery', 'Dairy', 'Other'];

  late TextEditingController _nameController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _stockController;
  late TextEditingController _lowStockController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _purchasePriceController = TextEditingController(text: widget.product != null ? widget.product!.purchasePrice.toStringAsFixed(0) : '');
    _salePriceController = TextEditingController(text: widget.product != null ? widget.product!.salePrice.toStringAsFixed(0) : '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _lowStockController = TextEditingController(text: widget.product?.lowStockThreshold.toString() ?? '5');

    if (widget.product?.category != null && _categories.contains(widget.product!.category)) {
      _selectedCategory = widget.product!.category!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isEditMode = widget.product != null;

      final productToSave = ProductEntity(
        id: isEditMode ? widget.product!.id : const Uuid().v4(),
        name: _nameController.text.trim(),
        purchasePrice: double.parse(_purchasePriceController.text.trim()),
        salePrice: double.parse(_salePriceController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        lowStockThreshold: int.parse(_lowStockController.text.trim()),
        category: _selectedCategory,
        createdAt: isEditMode ? widget.product!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      if (isEditMode) {
        await _repository.updateProduct(productToSave);
      } else {
        await _repository.addProduct(productToSave);
      }

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
    final isEditMode = widget.product != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Text(isEditMode ? 'Edit Product' : 'Add New Item', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
          : SingleChildScrollView(
        child: Column(
          children: [
            // Header Decoration
            Container(
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
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
                      _buildTextField(
                        controller: _nameController,
                        label: 'Product Name',
                        icon: Icons.shopping_bag_rounded,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryDropdown(),
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
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _lowStockController,
                              label: 'Low Stock Alert',
                              icon: Icons.notification_important_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ]),

                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 4,
                      ),
                      onPressed: _saveProduct,
                      child: const Text('Save To Inventory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (val) => setState(() => _selectedCategory = val!),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5)),
      ),
      validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
    );
  }
}