import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // ID generation ke liye
import '../../data/models/product_model.dart';

final productsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<ProductModel>>>((ref) {
  return ProductsNotifier();
});

class ProductsNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  ProductsNotifier() : super(const AsyncValue.loading()) {
    fetchProducts();
  }

  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

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

  Future<void> addProduct(ProductModel product) async {
    try {
      await _supabase.from('products').insert(product.toJson());
      await fetchProducts();
    } catch (e) {
      rethrow;
    }
  }

  // 🚀 NEW: Update Product (Inventory Edit)
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _supabase.from('products').update(product.toJson()).match({'id': product.id});
      await fetchProducts(); // List ko taaza (refresh) karne ke liye
    } catch (e) {
      rethrow;
    }
  }

  // 🚀 NEW: Delete Product (Inventory Delete)
  Future<void> deleteProduct(String productId) async {
    try {
      await _supabase.from('products').delete().match({'id': productId});
      await fetchProducts(); // List ko taaza (refresh) karne ke liye
    } catch (e) {
      rethrow;
    }
  }

  // --- 🛠️ Sale Save Function (For Cash & Khata tracking) ---
  Future<void> saveSale({required double totalAmount, required int itemsCount, required String type}) async {
    try {
      await _supabase.from('sales').insert({
        'id': _uuid.v4(),
        'total_amount': totalAmount,
        'items_count': itemsCount,
        'sale_type': type, // 'cash' ya 'khata'
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error saving sale record: $e");
      // Agar sale record save na bhi ho, hum process nahi rokenge
    }
  }

  // 🚀 NEW: Void Sale (Delete Sale Record)
  Future<void> deleteSale(String saleId) async {
    try {
      await _supabase.from('sales').delete().match({'id': saleId});
      // Note: Realtime stream on hone ki wajah se Dashboard aur Khata auto-update ho jayenge!
    } catch (e) {
      print("Error deleting sale record: $e");
      rethrow;
    }
  }

  Future<void> reduceStock(String productId, int quantitySold) async {
    try {
      final response = await _supabase
          .from('products')
          .select('stock')
          .eq('id', productId)
          .single();

      final currentStock = response['stock'] as int;
      int newStock = currentStock - quantitySold;
      if (newStock < 0) newStock = 0;

      await _supabase
          .from('products')
          .update({'stock': newStock})
          .eq('id', productId);

      await fetchProducts();
    } catch (e) {
      rethrow;
    }
  }
}