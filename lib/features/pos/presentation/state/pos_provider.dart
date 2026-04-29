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
}