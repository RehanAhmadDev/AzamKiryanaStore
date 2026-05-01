// lib/features/inventory/presentation/state/inventory_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/product_entity.dart';
import '../../data/repositories/inventory_repository_impl.dart';

// 1. Repository Provider: Ye Supabase se data laane ka connection banayega
final inventoryRepositoryProvider = Provider<InventoryRepositoryImpl>((ref) {
  return InventoryRepositoryImpl(Supabase.instance.client);
});

// 2. Main Inventory Provider: Ye poori app mein maal ko manage karega
final inventoryProvider = StateNotifierProvider<InventoryNotifier, List<ProductEntity>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return InventoryNotifier(repository);
});

class InventoryNotifier extends StateNotifier<List<ProductEntity>> {
  final InventoryRepositoryImpl repository;

  InventoryNotifier(this.repository) : super([]) {
    // App start hotay hi sara maal database se load ho jayega
    fetchProducts();
  }

  // --- 🛒 1. Fetch Products (Maal load karna) ---
  Future<void> fetchProducts() async {
    try {
      final products = await repository.getProducts();
      state = products; // Data provider mein save ho gaya!
    } catch (e) {
      print("Error fetching inventory: $e");
    }
  }

  // --- 📉 2. Reduce Stock (Sale hone par quantity kam karna) ---
  Future<void> reduceStock(String productId, int quantity) async {
    // UI mein foran update karein taake app fast lagay
    state = state.map((product) {
      if (product.id == productId) {
        return product.copyWith(stock: product.stock - quantity);
      }
      return product;
    }).toList();

    // Supabase DB mein bhi stock update karein
    try {
      final product = state.firstWhere((p) => p.id == productId);
      await Supabase.instance.client
          .from('products') // Apne table ka naam check kar lein agar different hai
          .update({'stock': product.stock})
          .eq('id', productId);
    } catch (e) {
      print("Error updating stock in DB: $e");
    }
  }

  // --- 💰 3. Save Sale (Checkout screen se hit hoga) ---
  Future<void> saveSale({required double totalAmount, required int itemsCount, required String type}) async {
    try {
      await Supabase.instance.client.from('sales').insert({
        'total_amount': totalAmount,
        'items_count': itemsCount,
        'sale_type': type,
        // Yahan aap apne sales table ke baqi columns set kar sakte hain
      });
    } catch (e) {
      print("Error saving sale: $e");
    }
  }

  // ==========================================
  // 🚨 4. LOW STOCK ALERTS LOGIC 🚨
  // ==========================================

  // Ye function wo items filter karega jinki quantity 'threshold' se kam ya barabar hai
  List<ProductEntity> getLowStockItems({int threshold = 5}) {
    return state.where((product) => product.stock <= threshold).toList();
  }
}