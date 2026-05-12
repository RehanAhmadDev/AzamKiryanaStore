// lib/features/inventory/data/repositories/inventory_repository_impl.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/product_model.dart';
import '../models/stock_log_model.dart'; // 🚀 NAYA IMPORT

class InventoryRepositoryImpl implements InventoryRepository {
  final SupabaseClient _supabaseClient;

  InventoryRepositoryImpl(this._supabaseClient);

  @override
  Future<List<ProductEntity>> getProducts() async {
    try {
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
        categoryId: product.categoryId,
        lowStockThreshold: product.lowStockThreshold,
        isActive: product.isActive,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      );

      await _supabaseClient.from('products').insert(productModel.toJson());

      // 🚀 LOG: Naya product add karne ka log
      await _saveStockLog(
        productId: product.id,
        productName: product.name,
        change: product.stock,
        prev: 0,
        newS: product.stock,
        reason: 'Initial Stock / New Product',
      );
    } catch (e) {
      throw Exception('Product add karne mein masla: $e');
    }
  }

  @override
  Future<void> updateProduct(ProductEntity product) async {
    try {
      // Pehle purana stock nikalte hain taake log mein farq pata chale
      final oldData = await _supabaseClient.from('products').select('stock').eq('id', product.id).single();
      int oldStock = oldData['stock'] as int;

      final productModel = ProductModel(
        id: product.id,
        name: product.name,
        barcode: product.barcode,
        purchasePrice: product.purchasePrice,
        salePrice: product.salePrice,
        stock: product.stock,
        categoryId: product.categoryId,
        lowStockThreshold: product.lowStockThreshold,
        isActive: product.isActive,
        createdAt: product.createdAt,
        updatedAt: DateTime.now(),
      );

      await _supabaseClient.from('products').update(productModel.toJson()).eq('id', product.id);

      // 🚀 LOG: Agar stock change hua hai toh log save karein
      if (oldStock != product.stock) {
        await _saveStockLog(
          productId: product.id,
          productName: product.name,
          change: product.stock - oldStock,
          prev: oldStock,
          newS: product.stock,
          reason: 'Manual Update / Restock',
        );
      }
    } catch (e) {
      throw Exception('Product update karne mein masla: $e');
    }
  }

  @override
  Future<void> reduceStock(String productId, int quantity) async {
    try {
      final data = await _supabaseClient.from('products').select('name, stock').eq('id', productId).single();
      int oldStock = data['stock'] as int;
      String pName = data['name'] as String;
      int newStock = oldStock - quantity;

      await _supabaseClient.from('products').update({'stock': newStock}).eq('id', productId);

      // 🚀 LOG: Sale ki wajah se stock kam hone ka log
      await _saveStockLog(
        productId: productId,
        productName: pName,
        change: -quantity,
        prev: oldStock,
        newS: newStock,
        reason: 'Sale (POS)',
      );
    } catch (e) {
      throw Exception('Stock kam karne mein masla: $e');
    }
  }

  // 🚀 HELPING FUNCTION: Logs save karne ke liye
  Future<void> _saveStockLog({
    required String productId,
    required String productName,
    required int change,
    required int prev,
    required int newS,
    required String reason,
  }) async {
    final log = {
      'product_id': productId,
      'product_name': productName,
      'change_amount': change,
      'previous_stock': prev,
      'new_stock': newS,
      'reason': reason,
    };
    await _supabaseClient.from('stock_logs').insert(log);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _supabaseClient.from('products').update({'is_active': false}).eq('id', id);
  }
}