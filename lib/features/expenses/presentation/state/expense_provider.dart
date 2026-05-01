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
}