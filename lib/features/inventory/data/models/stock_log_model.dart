// lib/features/inventory/data/models/stock_log_model.dart

import '../../domain/entities/stock_log_entity.dart';

class StockLogModel extends StockLogEntity {
  StockLogModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.changeAmount,
    required super.previousStock,
    required super.newStock, // 🚀 Ensure this matches Entity
    required super.reason,
    required super.createdAt,
  });

  factory StockLogModel.fromJson(Map<String, dynamic> json) {
    return StockLogModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      changeAmount: json['change_amount'] as int,
      previousStock: json['previous_stock'] as int,
      newStock: json['new_stock'] as int, // 🚀 Fix: JSON se 'new_stock' lo, variable 'newStock' mein dalo
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  // Database mein log bhejne ke liye
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'change_amount': changeAmount,
      'previous_stock': previousStock,
      'new_stock': newStock,
      'reason': reason,
    };
  }
}