// lib/features/inventory/presentation/state/inventory_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/product_entity.dart';
import '../../data/repositories/inventory_repository_impl.dart';

final inventoryRepositoryProvider = Provider<InventoryRepositoryImpl>((ref) {
  return InventoryRepositoryImpl(Supabase.instance.client);
});

final inventoryProvider = StateNotifierProvider<InventoryNotifier, List<ProductEntity>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return InventoryNotifier(repository);
});

class InventoryNotifier extends StateNotifier<List<ProductEntity>> {
  final InventoryRepositoryImpl repository;

  InventoryNotifier(this.repository) : super([]) {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final products = await repository.getProducts();
      state = products;
    } catch (e) {
      print("Error fetching inventory: $e");
    }
  }

  Future<void> reduceStock(String productId, int quantity) async {
    state = state.map((product) {
      if (product.id == productId) {
        return product.copyWith(stock: product.stock - quantity);
      }
      return product;
    }).toList();

    try {
      final product = state.firstWhere((p) => p.id == productId);
      await Supabase.instance.client
          .from('products')
          .update({'stock': product.stock})
          .eq('id', productId);
    } catch (e) {
      print("Error updating stock in DB: $e");
    }
  }

  // ==========================================
  // 💰 ADVANCED: PROFIT TRACKING SYSTEM 💰
  // ==========================================

  // Ab ye function total profit bhi calculate karke save karega
  Future<void> saveSaleWithProfit({
    required double totalAmount,
    required double totalProfit, // Ye hum checkout screen se calculate karke bhejenge
    required int itemsCount,
    required String type,
    String? customerId, // Khata sale ke liye
  }) async {
    try {
      await Supabase.instance.client.from('sales').insert({
        'total_amount': totalAmount,
        'total_profit': totalProfit, // Dashboard par "Net Profit" dikhane ke liye
        'items_count': itemsCount,
        'sale_type': type,
        'customer_id': customerId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Sale ke baad products list refresh karein taake dashboard update ho jaye
      await fetchProducts();
    } catch (e) {
      print("Error saving sale with profit: $e");
    }
  }

  List<ProductEntity> getLowStockItems({int threshold = 5}) {
    return state.where((product) => product.stock <= threshold).toList();
  }
}