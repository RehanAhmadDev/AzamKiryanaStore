import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/theme_provider.dart';
import '../state/inventory_provider.dart';

class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  void _shareToWhatsApp(List<dynamic> items) {
    if (items.isEmpty) return;
    String message = "📢 *Azam Kiryana Store - Shortage List*\n";
    message += "Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\n\n";
    for (var i = 0; i < items.length; i++) {
      message += "${i + 1}. ${items[i].name} (Baqi: ${items[i].stock})\n";
    }
    message += "\n*Kindly ye maal bhijwa dein.*";
    Clipboard.setData(ClipboardData(text: message));
  }

  void _showUpdateStockDialog(BuildContext context, WidgetRef ref, dynamic item) {
    final controller = TextEditingController(text: item.stock.toString());
    final primaryColor = ref.read(themeProvider).primaryColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Update Stock: ${item.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Naya maal kitna aaya hai? Total quantity update karein:'),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                labelText: 'Total Quantity',
                suffixText: 'Units',
                prefixIcon: const Icon(Icons.add_business_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newStock = int.tryParse(controller.text);
              if (newStock != null) {
                // 🚀 Method call to provider
                await ref.read(inventoryProvider.notifier).updateProduct(
                    item.copyWith(stock: newStock)
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} stock updated successfully!'),
                        backgroundColor: Colors.green,
                      )
                  );
                }
              }
            },
            child: const Text('Update Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    // 🚀 Threshold updated to 10 for better laptop visibility
    final lowStockItems = ref.watch(inventoryProvider.notifier).getLowStockItems(threshold: 10);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: themeState.primaryColor,
        title: const Text('Low Stock Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: () {
              _shareToWhatsApp(lowStockItems);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order List copied to clipboard! Paste it to WhatsApp.')),
              );
            },
            icon: const Icon(Icons.copy_all_rounded, color: Colors.white),
            label: const Text('Copy List', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Items Needing Refill', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Total ${lowStockItems.length} items are currently below 10 units',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () => ref.read(inventoryProvider.notifier).fetchProducts(),
                      icon: const Icon(Icons.sync_rounded, color: Colors.white),
                      label: const Text('Refresh Data', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: lowStockItems.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 60, color: Colors.green.shade300),
                          const SizedBox(height: 10),
                          const Text('All stock levels are healthy!', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                        : SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 40,
                        headingRowHeight: 60,
                        headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                        columns: const [
                          DataColumn(label: Text('PRODUCT NAME', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1))),
                          DataColumn(label: Text('STOCK LEFT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1))),
                          DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1))),
                          DataColumn(label: Text('UPDATE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1))),
                        ],
                        rows: lowStockItems.map((item) {
                          return DataRow(cells: [
                            DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                            DataCell(Text('${item.stock} Units',
                                style: TextStyle(color: item.stock == 0 ? Colors.red.shade700 : Colors.orange.shade700, fontWeight: FontWeight.bold))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: item.stock == 0 ? Colors.red.shade50 : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.stock == 0 ? 'Out of Stock' : 'Low Stock',
                                  style: TextStyle(color: item.stock == 0 ? Colors.red.shade700 : Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.blue, size: 26),
                                onPressed: () => _showUpdateStockDialog(context, ref, item),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
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
}