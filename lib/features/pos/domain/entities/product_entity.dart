class ProductEntity {
  final String id;
  final String name;
  final String? barcode;
  final double purchasePrice;
  final double salePrice;
  final int stock;
  final String? category;

  ProductEntity({
    required this.id,
    required this.name,
    this.barcode,
    required this.purchasePrice,
    required this.salePrice,
    required this.stock,
    this.category,
  });

  // Stock check karne ke liye helper
  bool get isOutOfStock => stock <= 0;
}