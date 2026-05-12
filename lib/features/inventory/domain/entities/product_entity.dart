// lib/features/inventory/domain/entities/product_entity.dart

class ProductEntity {
  final String id;
  final String name;
  final String? barcode;
  final double purchasePrice;
  final double salePrice;
  final int stock;
  // 🚀 NAYA: Category ID ko link kar diya gaya hai
  final String? categoryId;
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
    this.categoryId, // 🚀 NAYA PARAMETER
    this.lowStockThreshold = 5,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // 🚀 NAYA: JSON se object banate waqt category_id read karna
  factory ProductEntity.fromJson(Map<String, dynamic> json) {
    return ProductEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      barcode: json['barcode'] as String?,
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      salePrice: (json['sale_price'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      categoryId: json['category_id'] as String?, // 🚀 NAYA ADDED
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 5,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // 🚀 NAYA: Object se JSON banate waqt category_id bhejna
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'barcode': barcode,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'stock': stock,
      'category_id': categoryId, // 🚀 NAYA ADDED
      'low_stock_threshold': lowStockThreshold,
      'is_active': isActive,
    };
  }

  ProductEntity copyWith({
    String? id,
    String? name,
    String? barcode,
    double? purchasePrice,
    double? salePrice,
    int? stock,
    String? categoryId, // 🚀 NAYA PARAMETER
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
      categoryId: categoryId ?? this.categoryId, // 🚀 UPDATE
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get profitMargin => salePrice - purchasePrice;
  bool get isLowStock => stock <= lowStockThreshold;
}