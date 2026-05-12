// lib/features/inventory/domain/entities/stock_log_entity.dart

class StockLogEntity {
  final String id;
  final String productId;
  final String productName;
  final int changeAmount;
  final int previousStock;
  final int newStock;
  final String reason;
  final DateTime createdAt;

  StockLogEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.changeAmount,
    required this.previousStock,
    required this.newStock,
    required this.reason,
    required this.createdAt,
  });
}