import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/category_entity.dart';
import '../../data/repositories/category_repository_impl.dart';

final categoryRepositoryProvider = Provider<CategoryRepositoryImpl>((ref) {
  return CategoryRepositoryImpl(Supabase.instance.client);
});

final categoryProvider = StateNotifierProvider<CategoryNotifier, List<CategoryEntity>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryNotifier(repository);
});

class CategoryNotifier extends StateNotifier<List<CategoryEntity>> {
  final CategoryRepositoryImpl repository;

  CategoryNotifier(this.repository) : super([]) {
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final categories = await repository.getCategories();
      state = categories;
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<void> addCategory(CategoryEntity category) async {
    try {
      await repository.addCategory(category);
      await fetchCategories();
    } catch (e) {
      print("Error adding category: $e");
    }
  }

  Future<void> updateCategory(CategoryEntity category) async {
    try {
      await repository.updateCategory(category);
      await fetchCategories();
    } catch (e) {
      print("Error updating category: $e");
    }
  }

  Future<void> deleteCategory(String id) async {
    final previousState = state;
    state = state.where((c) => c.id != id).toList();
    try {
      await repository.deleteCategory(id);
    } catch (e) {
      print("Error deleting category: $e");
      state = previousState;
    }
  }
}