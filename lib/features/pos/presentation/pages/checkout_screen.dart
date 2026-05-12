// lib/features/pos/presentation/pages/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../../../../core/theme/theme_provider.dart';

import '../../../dashboard/presentation/state/business_provider.dart';
import '../state/cart_provider.dart';
import '../../../inventory/presentation/state/inventory_provider.dart';
import '../../../khata/presentation/state/state/khata_provider.dart';
import '../../../khata/domain/entities/khata_entry_entity.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isLoading = false;

  // 🚀 FIXED: Printing Logic (Italic aur Text Size errors nikaal diye hain)
  Future<void> _printReceipt(String type, String? customerName) async {
    try {
      final business = ref.read(businessProvider);
      final cartItems = ref.read(cartProvider);
      final total = ref.read(cartProvider.notifier).totalPrice;

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // Header: Store Name
      bytes += generator.text(business.storeName,
          styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('Smart POS Receipt', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.hr();

      // Info: Date & Type
      bytes += generator.text('Date: ${DateTime.now().toString().substring(0, 16)}');
      bytes += generator.text('Type: ${type.toUpperCase()}');
      if (customerName != null) bytes += generator.text('Customer: $customerName');
      bytes += generator.hr();

      // Table Header
      bytes += generator.row([
        PosColumn(text: 'Item', width: 6),
        PosColumn(text: 'Qty', width: 2),
        PosColumn(text: 'Total', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);

      // Cart Items
      for (var item in cartItems) {
        bytes += generator.row([
          PosColumn(text: item.name, width: 6),
          PosColumn(text: '${item.quantity}', width: 2),
          PosColumn(text: (item.price * item.quantity).toStringAsFixed(0), width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }

      bytes += generator.hr();

      // Total Amount
      bytes += generator.text('TOTAL: Rs. ${total.toStringAsFixed(0)}',
          styles: const PosStyles(align: PosAlign.right, bold: true));

      bytes += generator.feed(2);
      bytes += generator.text('Thank You for Shopping!', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.cut();

      debugPrint("Receipt Data Ready: ${bytes.length} bytes");
    } catch (e) {
      debugPrint("Printing Logic Error: $e");
    }
  }

  double _calculateTotalProfit() {
    final cartItems = ref.read(cartProvider);
    final allProducts = ref.read(inventoryProvider);
    double totalProfit = 0;

    for (var cartItem in cartItems) {
      try {
        final product = allProducts.firstWhere((p) => p.id == cartItem.productId);
        double itemProfit = (cartItem.price - product.purchasePrice) * cartItem.quantity;
        totalProfit += itemProfit;
      } catch (e) {
        debugPrint("Profit calculation error for ${cartItem.name}: $e");
      }
    }
    return totalProfit;
  }

  void _showReceiptPopup(String type, String? customerName) {
    final cartItems = ref.read(cartProvider);
    final totalPrice = ref.read(cartProvider.notifier).totalPrice;
    final themeState = ref.read(themeProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 60),
            const SizedBox(height: 16),
            const Text('Sale Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Date:'), Text(DateTime.now().toString().substring(0, 16))]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Type:'), Text(type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))]),
            if (customerName != null) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Customer:'), Text(customerName)]),
            const Divider(height: 30),
            ...cartItems.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${item.name} x${item.quantity}'),
                Text('Rs. ${(item.price * item.quantity).toStringAsFixed(0)}'),
              ]),
            )).toList(),
            const Divider(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Rs. ${totalPrice.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: themeState.primaryColor)),
            ]),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: themeState.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Back to Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _processCashPayment() async {
    final cartItems = ref.read(cartProvider);
    final totalPrice = ref.read(cartProvider.notifier).totalPrice;
    final totalProfit = _calculateTotalProfit();

    setState(() => _isLoading = true);

    try {
      for (var item in cartItems) {
        await ref.read(inventoryProvider.notifier).reduceStock(item.productId, item.quantity);
      }

      await ref.read(inventoryProvider.notifier).saveSaleWithProfit(
        totalAmount: totalPrice,
        totalProfit: totalProfit,
        itemsCount: cartItems.length,
        type: 'cash',
      );

      await _printReceipt('cash', null);
      _showReceiptPopup('cash', null);

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processKhataPayment(double totalAmount, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 600),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final customerState = ref.watch(customerProvider);

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Customer for Khata',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  Expanded(
                    child: customerState.when(
                      loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                      data: (customers) {
                        if (customers.isEmpty) {
                          return const Center(child: Text('No customers found.', textAlign: TextAlign.center));
                        }

                        return ListView.builder(
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            final customer = customers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primaryColor.withOpacity(0.1),
                                child: Text(customer.name[0].toUpperCase(), style: TextStyle(color: primaryColor)),
                              ),
                              title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(customer.phone),
                              onTap: () => _confirmKhataSale(customer, totalAmount),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmKhataSale(dynamic customer, double totalAmount) async {
    Navigator.pop(context);
    final cartItems = ref.read(cartProvider);
    final totalProfit = _calculateTotalProfit();

    setState(() => _isLoading = true);

    try {
      for (var item in cartItems) {
        await ref.read(inventoryProvider.notifier).reduceStock(item.productId, item.quantity);
      }

      final String itemDetails = cartItems.map((item) => '${item.name} x${item.quantity}').join(', ');

      final entry = KhataEntryEntity(
        id: '',
        customerId: customer.id,
        amount: totalAmount,
        type: EntryType.gave,
        date: DateTime.now(),
        notes: itemDetails,
      );

      await ref.read(customerProvider.notifier).addEntry(entry);

      await ref.read(inventoryProvider.notifier).saveSaleWithProfit(
        totalAmount: totalAmount,
        totalProfit: totalProfit,
        itemsCount: cartItems.length,
        type: 'khata',
        customerId: customer.id,
      );

      await _printReceipt('khata', customer.name);
      _showReceiptPopup('khata', customer.name);

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final cartList = ref.watch(cartProvider);
    final totalPrice = ref.watch(cartProvider.notifier).totalPrice;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Checkout Bill', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: themeState.primaryColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: cartList.isEmpty
                  ? const Center(child: Text('Your cart is empty!'))
                  : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cartList.length,
                      itemBuilder: (context, index) {
                        final item = cartList[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Rs. ${item.price.toStringAsFixed(0)} x ${item.quantity}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: _isLoading ? null : () => ref.read(cartProvider.notifier).decreaseQuantity(item.productId),
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF10B981)),
                                  onPressed: _isLoading ? null : () => ref.read(cartProvider.notifier).addItem(item),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        )
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              Text('Rs. ${totalPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: themeState.primaryColor)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _isLoading ? null : () => _processKhataPayment(totalPrice, themeState.primaryColor),
                                  icon: const Icon(Icons.menu_book, color: Colors.white),
                                  label: const Text('Khata (Credit)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeState.primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _isLoading ? null : _processCashPayment,
                                  icon: const Icon(Icons.payments, color: Colors.white),
                                  label: const Text('Cash Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Center(child: CircularProgressIndicator(color: themeState.primaryColor)),
        ],
      ),
    );
  }
}