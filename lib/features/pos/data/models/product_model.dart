import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  ProductModel({
    required super.id,
    required super.name,
    super.barcode,
    required super.purchasePrice,
    required super.salePrice,
    required super.stock,
    super.category,
  });

  // Supabase (JSON) se data lene ke liye
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      barcode: json['barcode'],
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      salePrice: (json['sale_price'] as num).toDouble(),
      stock: json['stock'] as int,
      category: json['category'],
    );
  }

  // Data ko Supabase mein bhejne ke liye (JSON banany ke liye)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'barcode': barcode,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'stock': stock,
      'category': category,
    };
  }
}