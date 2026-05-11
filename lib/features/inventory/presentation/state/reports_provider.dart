import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Report Model for easy data handling
class ReportData {
  final double totalSales;
  final double totalProfit;
  final double totalExpenses;
  final double netProfit;

  ReportData({
    required this.totalSales,
    required this.totalProfit,
    required this.totalExpenses,
    required this.netProfit,
  });
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, AsyncValue<ReportData>>((ref) {
  return ReportsNotifier();
});

class ReportsNotifier extends StateNotifier<AsyncValue<ReportData>> {
  ReportsNotifier() : super(const AsyncValue.loading()) {
    fetchReportData();
  }

  final _supabase = Supabase.instance.client;

  Future<void> fetchReportData({DateTimeRange? dateRange}) async {
    state = const AsyncValue.loading();
    try {
      // 1. Fetch Sales Data - 🚀 Fixed column name to total_profit
      var salesQuery = _supabase.from('sales').select('total_amount, total_profit, created_at');

      // 2. Fetch Expenses Data
      var expensesQuery = _supabase.from('expenses').select('amount, date');

      // Date range filtering
      if (dateRange != null) {
        salesQuery = salesQuery.gte('created_at', dateRange.start.toIso8601String())
            .lte('created_at', dateRange.end.toIso8601String());
        expensesQuery = expensesQuery.gte('date', dateRange.start.toIso8601String())
            .lte('date', dateRange.end.toIso8601String());
      }

      final salesResponse = await salesQuery;
      final expensesResponse = await expensesQuery;

      double totalSales = 0;
      double totalProfit = 0;
      double totalExpenses = 0;

      for (var sale in salesResponse) {
        totalSales += (sale['total_amount'] as num).toDouble();
        // 🚀 Fixed key name to total_profit
        totalProfit += (sale['total_profit'] as num? ?? 0).toDouble();
      }

      for (var expense in expensesResponse) {
        totalExpenses += (expense['amount'] as num).toDouble();
      }

      final netProfit = totalProfit - totalExpenses;

      state = AsyncValue.data(ReportData(
        totalSales: totalSales,
        totalProfit: totalProfit,
        totalExpenses: totalExpenses,
        netProfit: netProfit,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}