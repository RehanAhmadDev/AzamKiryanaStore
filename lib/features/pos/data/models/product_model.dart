// lib/features/pos/data/models/product_model.dart

import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  ProductModel({
    required super.id,
    required super.name,
    super.barcode,
    required super.purchasePrice,
    required super.salePrice,
    required super.stock,
    super.categoryId, // 🚀 UPDATE
    super.lowStockThreshold = 5,
    super.isActive = true,
    required super.createdAt,
    required super.updatedAt,
  });

  // Supabase (JSON) se Model mein convert karne ke liye
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      barcode: json['barcode'] as String?,
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      salePrice: (json['sale_price'] as num).toDouble(),
      stock: json['stock'] as int,
      categoryId: json['category_id'] as String?, // 🚀 UPDATE
      lowStockThreshold: json['low_stock_threshold'] as int? ?? 5,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
    );
  }

  // App se Supabase (JSON) mein data bhejne ke liye
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'barcode': barcode,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'stock': stock,
      'category_id': categoryId, // 🚀 UPDATE
      'low_stock_threshold': lowStockThreshold,
      'is_active': isActive,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}