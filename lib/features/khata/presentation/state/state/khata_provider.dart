import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/khata_supabase_data_source.dart';
import '../../../data/repositories_impl/khata_repository_impl.dart';
import '../../../domain/entities/customer_entity.dart';
import '../../../domain/entities/khata_entry_entity.dart';
import '../../../domain/repositories/khata_repository.dart';

final khataRemoteDataSourceProvider = Provider<KhataRemoteDataSource>((ref) {
  return KhataSupabaseDataSourceImpl();
});

final khataRepositoryProvider = Provider<KhataRepository>((ref) {
  final dataSource = ref.read(khataRemoteDataSourceProvider);
  return KhataRepositoryImpl(remoteDataSource: dataSource);
});

// --- Customer List Notifier ---
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

  Future<void> addEntry(KhataEntryEntity entry) async {
    try {
      await repository.addKhataEntry(entry);
      await loadCustomers();
    } catch (e, stackTrace) {
      print("Error adding entry: $e");
    }
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<List<CustomerEntity>>>((ref) {
  final repository = ref.read(khataRepositoryProvider);
  return CustomerNotifier(repository: repository);
});

// --- NEW: Transaction History Notifier ---
// Yeh kisi specific customer ki saari entries fetch karne ke liye hai
class TransactionNotifier extends StateNotifier<AsyncValue<List<KhataEntryEntity>>> {
  final KhataRepository repository;
  final String customerId;

  TransactionNotifier({required this.repository, required this.customerId}) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      state = const AsyncValue.loading();
      final entries = await repository.getKhataEntriesByCustomerId(customerId);
      state = AsyncValue.data(entries);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Family provider use kiya hai taake customerId pass ki ja sake
final transactionProvider = StateNotifierProvider.family<TransactionNotifier, AsyncValue<List<KhataEntryEntity>>, String>((ref, customerId) {
  final repository = ref.read(khataRepositoryProvider);
  return TransactionNotifier(repository: repository, customerId: customerId);
});