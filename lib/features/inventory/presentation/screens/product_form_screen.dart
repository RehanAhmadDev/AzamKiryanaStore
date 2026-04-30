// lib/features/inventory/presentation/screens/product_form_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Is ke liye shayad aapko uuid package add karna parre agar error aaye
import '../../domain/entities/product_entity.dart';
import '../../data/repositories/inventory_repository_impl.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductEntity? product; // Agar ye null hai to Add Mode, agar data hai to Edit Mode

  const ProductFormScreen({Key? key, this.product}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = InventoryRepositoryImpl(Supabase.instance.client);

  bool _isLoading = false;

  // Text Controllers
  late TextEditingController _nameController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _stockController;
  late TextEditingController _lowStockController;

  @override
  void initState() {
    super.initState();
    // Agar Edit mode hai toh purana data controllers mein daal do, warna khali rakho
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _purchasePriceController = TextEditingController(text: widget.product != null ? widget.product!.purchasePrice.toStringAsFixed(0) : '');
    _salePriceController = TextEditingController(text: widget.product != null ? widget.product!.salePrice.toStringAsFixed(0) : '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _lowStockController = TextEditingController(text: widget.product?.lowStockThreshold.toString() ?? '5');
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
        id: isEditMode ? widget.product!.id : const Uuid().v4(), // Naya UUID generate karna
        name: _nameController.text.trim(),
        purchasePrice: double.parse(_purchasePriceController.text.trim()),
        salePrice: double.parse(_salePriceController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        lowStockThreshold: int.parse(_lowStockController.text.trim()),
        createdAt: isEditMode ? widget.product!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      if (isEditMode) {
        await _repository.updateProduct(productToSave);
      } else {
        await _repository.addProduct(productToSave);
      }

      if (mounted) {
        // Form close kar ke pichli screen ko batana ke data update ho gaya (true)
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Product' : 'Add New Product'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Product Name (e.g., Lays Masala)',
                icon: Icons.shopping_bag_outlined,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _purchasePriceController,
                      label: 'Purchase Price',
                      icon: Icons.money_off,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _salePriceController,
                      label: 'Sale Price',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
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
                      label: 'Current Stock',
                      icon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _lowStockController,
                      label: 'Low Alert At',
                      icon: Icons.warning_amber_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveProduct,
                child: const Text(
                  'Save Product',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required field';
        }
        return null;
      },
    );
  }
}