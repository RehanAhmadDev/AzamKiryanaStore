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
  final Ref ref;

  CustomerNotifier({required this.repository, required this.ref}) : super(const AsyncValue.loading()) {
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

  // 🚀 NEW: Update Customer Name/Phone Logic
  Future<void> updateCustomer(CustomerEntity customer) async {
    try {
      await repository.updateCustomer(customer);
      await loadCustomers(); // UI List refresh karne ke liye
    } catch (e) {
      print("Error updating customer: $e");
    }
  }

  Future<void> addEntry(KhataEntryEntity entry) async {
    try {
      await repository.addKhataEntry(entry);
      await loadCustomers();
      ref.invalidate(transactionProvider(entry.customerId));
    } catch (e, stackTrace) {
      print("Error adding entry: $e");
    }
  }

  Future<void> updateEntry(KhataEntryEntity entry) async {
    try {
      await repository.updateKhataEntry(entry);
      await loadCustomers();
      ref.invalidate(transactionProvider(entry.customerId));
    } catch (e) {
      print("Error updating entry: $e");
    }
  }

  Future<void> deleteEntry(String entryId, String customerId) async {
    try {
      await repository.deleteKhataEntry(entryId);
      await loadCustomers();
      ref.invalidate(transactionProvider(customerId));
    } catch (e) {
      print("Error deleting entry: $e");
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await repository.deleteCustomer(customerId);
      await loadCustomers();
    } catch (e) {
      print("Error deleting customer: $e");
    }
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<List<CustomerEntity>>>((ref) {
  final repository = ref.read(khataRepositoryProvider);
  return CustomerNotifier(repository: repository, ref: ref);
});

// --- Transaction History Notifier ---
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

final transactionProvider = StateNotifierProvider.family<TransactionNotifier, AsyncValue<List<KhataEntryEntity>>, String>((ref, customerId) {
  final repository = ref.read(khataRepositoryProvider);
  return TransactionNotifier(repository: repository, customerId: customerId);
});