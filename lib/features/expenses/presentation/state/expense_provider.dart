import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/expense_model.dart';

final expenseProvider = StateNotifierProvider<ExpenseNotifier, AsyncValue<void>>((ref) {
  return ExpenseNotifier();
});

class ExpenseNotifier extends StateNotifier<AsyncValue<void>> {
  ExpenseNotifier() : super(const AsyncData(null));

  Future<void> addExpense(ExpenseModel expense) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client
          .from('expenses')
          .insert(expense.toJson());

      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> deleteExpense(String id) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client
          .from('expenses')
          .delete()
          .match({'id': id});

      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  // 🚀 Naya Update Function Jo Error Fix Karega
  Future<void> updateExpense(ExpenseModel expense) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client
          .from('expenses')
          .update(expense.toJson())
          .match({'id': expense.id!}); // ID ke zariye specific record update hoga

      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}