import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/category_entity.dart';

class CategoryRepositoryImpl {
  final SupabaseClient client;

  CategoryRepositoryImpl(this.client);

  Future<List<CategoryEntity>> getCategories() async {
    final response = await client.from('categories').select().order('created_at', ascending: false);
    return (response as List).map((json) => CategoryEntity.fromJson(json)).toList();
  }

  Future<void> addCategory(CategoryEntity category) async {
    await client.from('categories').insert(category.toJson());
  }

  Future<void> updateCategory(CategoryEntity category) async {
    await client.from('categories').update(category.toJson()).eq('id', category.id);
  }

  Future<void> deleteCategory(String id) async {
    await client.from('categories').delete().eq('id', id);
  }
}