import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/khata_supabase_data_source.dart'; // Naya Remote Source
import '../../../data/repositories_impl/khata_repository_impl.dart';
import '../../../domain/entities/customer_entity.dart';
import '../../../domain/repositories/khata_repository.dart';

// 1. Data Source Provider (Supabase initialization)
// Ab hum local ki bajaye remote (cloud) data source use kar rahe hain
final khataRemoteDataSourceProvider = Provider<KhataRemoteDataSource>((ref) {
  return KhataSupabaseDataSourceImpl();
});

// 2. Repository Provider (Domain aur Cloud Data ka connection)
final khataRepositoryProvider = Provider<KhataRepository>((ref) {
  final dataSource = ref.read(khataRemoteDataSourceProvider);
  return KhataRepositoryImpl(remoteDataSource: dataSource);
});

// 3. Customer State Notifier (UI ko control karne ke liye)
class CustomerNotifier extends StateNotifier<AsyncValue<List<CustomerEntity>>> {
  final KhataRepository repository;

  CustomerNotifier({required this.repository}) : super(const AsyncValue.loading()) {
    loadCustomers(); // Jaise hi app khulegi, cloud se data load hoga
  }

  // Supabase (Cloud) se saare customers lana
  Future<void> loadCustomers() async {
    try {
      state = const AsyncValue.loading();
      final customers = await repository.getAllCustomers();
      state = AsyncValue.data(customers);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Naya customer add karna aur cloud list refresh karna
  Future<void> addCustomer(CustomerEntity customer) async {
    try {
      // Step 1: Cloud par add karo
      await repository.addCustomer(customer);
      // Step 2: UI refresh karne ke liye dobara load karo
      await loadCustomers();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// 4. Customer State Provider (UI isko sunega / listen karega)
final customerProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<List<CustomerEntity>>>((ref) {
  final repository = ref.read(khataRepositoryProvider);
  return CustomerNotifier(repository: repository);
});