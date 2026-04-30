// lib/features/inventory/domain/repositories/inventory_repository.dart

import '../entities/product_entity.dart';

abstract class InventoryRepository {
  // Saare products database se lane ke liye
  Future<List<ProductEntity>> getProducts();

  // Naya product database mein add karne ke liye
  Future<void> addProduct(ProductEntity product);

  // Kisi product ki details ya stock update karne ke liye
  Future<void> updateProduct(ProductEntity product);

  // Kisi product ko delete (ya inactive) karne ke liye
  Future<void> deleteProduct(String id);
}