// lib/features/inventory/presentation/state/stock_logs_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/stock_log_model.dart';


final stockLogsProvider = FutureProvider<List<StockLogModel>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('stock_logs')
      .select()
      .order('created_at', ascending: false); // Taza tareen logs upar

  return response.map((json) => StockLogModel.fromJson(json)).toList();
});