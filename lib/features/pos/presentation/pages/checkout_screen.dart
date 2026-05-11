// lib/features/pos/presentation/pages/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';

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

  Future<void> _processCashPayment() async {
    final themeState = ref.read(themeProvider);
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

      ref.read(cartProvider.notifier).clearCart();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cash Sale Successful! Profit Recorded.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
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

      ref.read(cartProvider.notifier).clearCart();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill added to ${customer.name}\'s Khata!'),
            backgroundColor: const Color(0xFFF59E0B),
          ),
        );
        Navigator.pop(context);
      }
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
    // 🚀 Theme watch
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
        backgroundColor: themeState.primaryColor, // 🚀 Dynamic
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 🚀 DESKTOP FIX: Responsive width 1200
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
                                    backgroundColor: themeState.primaryColor, // 🚀 Dynamic
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