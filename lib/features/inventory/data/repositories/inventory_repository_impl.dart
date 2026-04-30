// lib/features/inventory/data/repositories/inventory_repository_impl.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/product_model.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final SupabaseClient _supabaseClient;

  InventoryRepositoryImpl(this._supabaseClient);

  @override
  Future<List<ProductEntity>> getProducts() async {
    try {
      // Sirf wo products layen jo active hain, aur A-Z tarteeb mein
      final response = await _supabaseClient
          .from('products')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);

      return response.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Products lane mein masla: $e');
    }
  }

  @override
  Future<void> addProduct(ProductEntity product) async {
    try {
      final productModel = ProductModel(
        id: product.id,
        name: product.name,
        barcode: product.barcode,
        purchasePrice: product.purchasePrice,
        salePrice: product.salePrice,
        stock: product.stock,
        category: product.category,
        lowStockThreshold: product.lowStockThreshold,
        isActive: product.isActive,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      );

      // Supabase mein naya record insert karna
      await _supabaseClient.from('products').insert(productModel.toJson());
    } catch (e) {
      throw Exception('Product add karne mein masla: $e');
    }
  }

  @override
  Future<void> updateProduct(ProductEntity product) async {
    try {
      final productModel = ProductModel(
        id: product.id,
        name: product.name,
        barcode: product.barcode,
        purchasePrice: product.purchasePrice,
        salePrice: product.salePrice,
        stock: product.stock,
        category: product.category,
        lowStockThreshold: product.lowStockThreshold,
        isActive: product.isActive,
        createdAt: product.createdAt,
        updatedAt: DateTime.now(), // Update time current set kar diya
      );

      // Supabase mein record update karna
      await _supabaseClient
          .from('products')
          .update(productModel.toJson())
          .eq('id', product.id);
    } catch (e) {
      throw Exception('Product update karne mein masla: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      // PRO TIP: Hum item ko hamesha ke liye delete nahi kar rahe.
      // Hum sirf isko 'is_active: false' kar rahe hain (Soft Delete).
      // Is se aapki purani raseedon (receipts) mein is item ka naam kharab nahi hoga!
      await _supabaseClient
          .from('products')
          .update({'is_active': false})
          .eq('id', id);
    } catch (e) {
      throw Exception('Product delete karne mein masla: $e');
    }
  }
}