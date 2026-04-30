import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/product_model.dart';

// Products ki list ko handle karne wala provider
final productsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<ProductModel>>>((ref) {
  return ProductsNotifier();
});

class ProductsNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  ProductsNotifier() : super(const AsyncValue.loading()) {
    fetchProducts();
  }

  final _supabase = Supabase.instance.client;

  // Database se products lana
  Future<void> fetchProducts() async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.from('products').select().order('name');
      final products = (response as List).map((e) => ProductModel.fromJson(e)).toList();
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Naya Product add karna
  Future<void> addProduct(ProductModel product) async {
    try {
      await _supabase.from('products').insert(product.toJson());
      await fetchProducts(); // List refresh karein
    } catch (e) {
      rethrow;
    }
  }

  // --- 🛠️ NEW: Stock Deduction Function ---
  // Sale hone ke baad item ka stock kam karne ke liye
  Future<void> reduceStock(String productId, int quantitySold) async {
    try {
      // 1. Fetch current stock from database
      final response = await _supabase
          .from('products')
          .select('stock')
          .eq('id', productId)
          .single();

      final currentStock = response['stock'] as int;

      // 2. Calculate new stock (Ensure it doesn't go below 0)
      int newStock = currentStock - quantitySold;
      if (newStock < 0) newStock = 0;

      // 3. Update the stock in database
      await _supabase
          .from('products')
          .update({'stock': newStock})
          .eq('id', productId);

      // 4. Refresh the UI list
      await fetchProducts();
    } catch (e) {
      rethrow;
    }
  }
}