import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../state/pos_provider.dart';
import '../widgets/barcode_scanner_widget.dart'; // Scanner widget ka import

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Inventory / Stock',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: productsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(
                child: Text('No products in stock. Add your first item!'));
          }
          return ListView.builder(
            itemCount: products.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0F172A).withOpacity(0.05),
                    child: const Icon(Icons.shopping_bag_outlined,
                        color: Color(0xFF0F172A)),
                  ),
                  title: Text(product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Sale: Rs. ${product.salePrice.toStringAsFixed(0)} | Stock: ${product.stock}'),
                  trailing: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (product.stock < 5 ? Colors.red : Colors.green)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.stock < 5 ? 'Low Stock' : 'In Stock',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: product.stock < 5 ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context, ref),
        label: const Text('Add Product',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
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
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_business, color: Color(0xFF0F172A)),
              SizedBox(width: 10),
              Text('New Product',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                    Expanded(
                        child: _buildField(
                            barcodeController, 'Barcode', Icons.qr_code)),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A)),
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
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField(purchaseController, 'Purchase Price', Icons.download,
                    isNumber: true),
                const SizedBox(height: 12),
                _buildField(saleController, 'Sale Price', Icons.sell,
                    isNumber: true),
                const SizedBox(height: 12),
                _buildField(stockController, 'Initial Stock', Icons.inventory,
                    isNumber: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
              const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
                    id: '', // Supabase handle karega
                    name: nameController.text,
                    barcode: barcodeController.text.isEmpty
                        ? null
                        : barcodeController.text,
                    purchasePrice:
                    double.tryParse(purchaseController.text) ?? 0.0,
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
              child: const Text('Save Product',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // UI Helper for fields
  Widget _buildField(TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
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