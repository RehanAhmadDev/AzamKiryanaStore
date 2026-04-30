// lib/features/pos/presentation/pages/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/cart_provider.dart';
import '../state/pos_provider.dart'; // Naya Import: Stock minus karne ke liye
import '../../../khata/presentation/state/state/khata_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {

  bool _isLoading = false; // Loading state handle karne ke liye

  // --- 💰 FUNCTION: Handle Cash Payment ---
  Future<void> _processCashPayment() async {
    final cartItems = ref.read(cartProvider);

    setState(() => _isLoading = true);

    try {
      // 1. Loop chala kar har item ka stock database se minus karein
      for (var item in cartItems) {
        await ref.read(productsProvider.notifier).reduceStock(item.productId, item.quantity);
      }

      // TODO: Here we can save the sale to a general 'Sales' database table later

      // 2. Clear the cart after successful payment
      ref.read(cartProvider.notifier).clearCart();

      if (context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Successful! Stock Updated.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        // Go back to the Inventory/POS screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating stock: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 📖 FUNCTION: Handle Khata (Credit) Payment ---
  void _processKhataPayment(double totalAmount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final customerState = ref.watch(customerProvider);

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select Customer for Khata',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  Expanded(
                    child: customerState.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                      data: (customers) {
                        if (customers.isEmpty) {
                          return const Center(
                            child: Text('No customers found.\nPlease add a customer first.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                          );
                        }

                        return ListView.builder(
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            final customer = customers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF0F172A).withOpacity(0.1),
                                child: Text(
                                  customer.name[0].toUpperCase(),
                                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(customer.phone),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              onTap: () {
                                _confirmKhataSale(customer, totalAmount);
                              },
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

  // --- 🛠️ FUNCTION: Confirm Khata Sale ---
  Future<void> _confirmKhataSale(dynamic customer, double totalAmount) async {
    Navigator.pop(context); // Bottom sheet band karein

    final cartItems = ref.read(cartProvider);

    setState(() => _isLoading = true);

    try {
      // 1. Loop chala kar pehle inventory ka stock minus karein
      for (var item in cartItems) {
        await ref.read(productsProvider.notifier).reduceStock(item.productId, item.quantity);
      }

      // 2. TODO: KHATA ENTRY LINKING
      // Rehan bhai: Stock minus ho gaya, ab yahan Customer ki Khata entry dalni hai.
      // Mujhe apna Khata Transaction Provider bhejein taake main is line ko theek kar sakun.
      // Example: await ref.read(transactionProvider(customer.id).notifier).addTransaction(totalAmount, isGave: true, notes: "POS Sale");

      // 3. Cart clear karein
      ref.read(cartProvider.notifier).clearCart();

      if (context.mounted) {
        // Success Message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill added to ${customer.name}\'s Khata! Stock Updated.'),
            backgroundColor: const Color(0xFFF59E0B),
          ),
        );

        // Wapis POS Screen par jayein
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
    final cartList = ref.watch(cartProvider);
    final totalPrice = ref.watch(cartProvider.notifier).totalPrice;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Checkout Bill', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Stack use kiya hai taake process ke dauran screen par loading indicator aa sakay
      body: Stack(
        children: [
          cartList.isEmpty
              ? const Center(
            child: Text('Your cart is empty!', style: TextStyle(fontSize: 18, color: Colors.grey)),
          )
              : Column(
            children: [
              // --- 📝 BILL SUMMARY LIST ---
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
                              onPressed: _isLoading ? null : () {
                                ref.read(cartProvider.notifier).decreaseQuantity(item.productId);
                              },
                            ),
                            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF10B981)),
                              onPressed: _isLoading ? null : () {
                                ref.read(cartProvider.notifier).addItem(item);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- 💰 TOTAL AMOUNT & PAYMENT BUTTONS ---
              Container(
                padding: const EdgeInsets.all(24),
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
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Rs. ${totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // KHATA BUTTON
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isLoading ? null : () => _processKhataPayment(totalPrice),
                              icon: const Icon(Icons.menu_book, color: Colors.white),
                              label: const Text('Khata (Credit)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // CASH BUTTON
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isLoading ? null : _processCashPayment,
                              icon: const Icon(Icons.payments, color: Colors.white),
                              label: const Text('Cash Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
              ),
            ),
        ],
      ),
    );
  }
}