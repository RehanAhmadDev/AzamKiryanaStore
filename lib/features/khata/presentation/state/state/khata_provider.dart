import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/khata_supabase_data_source.dart';
import '../../../data/repositories_impl/khata_repository_impl.dart';
import '../../../domain/entities/customer_entity.dart';
import '../../../domain/entities/khata_entry_entity.dart'; // Naya Import
import '../../../domain/repositories/khata_repository.dart';

final khataRemoteDataSourceProvider = Provider<KhataRemoteDataSource>((ref) {
  return KhataSupabaseDataSourceImpl();
});

final khataRepositoryProvider = Provider<KhataRepository>((ref) {
  final dataSource = ref.read(khataRemoteDataSourceProvider);
  return KhataRepositoryImpl(remoteDataSource: dataSource);
});

class CustomerNotifier extends StateNotifier<AsyncValue<List<CustomerEntity>>> {
  final KhataRepository repository;

  CustomerNotifier({required this.repository}) : super(const AsyncValue.loading()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    try {
      state = const AsyncValue.loading();
      final customers = await repository.getAllCustomers();
      state = AsyncValue.data(customers);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addCustomer(CustomerEntity customer) async {
    try {
      await repository.addCustomer(customer);
      await loadCustomers();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // --- NAYA FUNCTION: Transaction Add karne ke liye ---
  Future<void> addEntry(KhataEntryEntity entry) async {
    try {
      // 1. Cloud par entry save karo aur balance update karo
      await repository.addKhataEntry(entry);

      // 2. UI ki list ko refresh karo taake naya balance nazar aaye
      await loadCustomers();
    } catch (e, stackTrace) {
      // Error handle karne ke liye aap yahan logging add kar sakte hain
      print("Error adding entry: $e");
    }
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<List<CustomerEntity>>>((ref) {
  final repository = ref.read(khataRepositoryProvider);
  return CustomerNotifier(repository: repository);
});