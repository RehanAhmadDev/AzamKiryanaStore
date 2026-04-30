// lib/features/pos/presentation/state/cart_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model to hold individual cart items
class CartItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  // Helper method to update quantity easily
  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }
}

// StateNotifier to manage the cart logic (Add, Remove, Update)
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  // Add an item to the cart or increase quantity if it already exists
  void addItem(CartItem item) {
    final existingIndex = state.indexWhere((element) => element.productId == item.productId);

    if (existingIndex >= 0) {
      final updatedCart = [...state];
      updatedCart[existingIndex] = updatedCart[existingIndex].copyWith(
        quantity: updatedCart[existingIndex].quantity + 1,
      );
      state = updatedCart;
    } else {
      state = [...state, item];
    }
  }

  // Completely remove an item from the cart
  void removeItem(String productId) {
    state = state.where((item) => item.productId != productId).toList();
  }

  // Decrease quantity of an item, remove if quantity becomes 0
  void decreaseQuantity(String productId) {
    final existingIndex = state.indexWhere((element) => element.productId == productId);

    if (existingIndex >= 0) {
      if (state[existingIndex].quantity > 1) {
        final updatedCart = [...state];
        updatedCart[existingIndex] = updatedCart[existingIndex].copyWith(
          quantity: updatedCart[existingIndex].quantity - 1,
        );
        state = updatedCart;
      } else {
        removeItem(productId);
      }
    }
  }

  // Clear the entire cart after a successful sale
  void clearCart() {
    state = [];
  }

  // Calculate the total price of all items in the cart
  double get totalPrice {
    return state.fold(0, (total, item) => total + (item.price * item.quantity));
  }
}

// The Riverpod provider to access the cart anywhere in the app
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});