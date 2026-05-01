// lib/features/inventory/domain/entities/product_entity.dart

class ProductEntity {
  final String id;
  final String name;
  final String? barcode;
  final double purchasePrice;
  final double salePrice;
  final int stock;
  final String? category;
  final int lowStockThreshold;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductEntity({
    required this.id,
    required this.name,
    this.barcode,
    required this.purchasePrice,
    required this.salePrice,
    required this.stock,
    this.category,
    this.lowStockThreshold = 5,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  ProductEntity copyWith({
    String? id,
    String? name,
    String? barcode,
    double? purchasePrice,
    double? salePrice,
    int? stock,
    String? category,
    int? lowStockThreshold,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Profit nikalne ka formula
  double get profitMargin => salePrice - purchasePrice;

  // Stock check karne ka formula
  bool get isLowStock => stock <= lowStockThreshold;
}