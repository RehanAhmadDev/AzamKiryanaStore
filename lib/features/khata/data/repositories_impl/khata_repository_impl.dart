import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/khata_entry_entity.dart';
import '../../domain/repositories/khata_repository.dart';
import '../datasources/khata_supabase_data_source.dart'; // Naya Remote Data Source
import '../models/customer_model.dart';
import '../models/khata_entry_model.dart';

class KhataRepositoryImpl implements KhataRepository {
  // Ab hum local ki jagah remote (Supabase) data source use kar rahe hain
  final KhataRemoteDataSource remoteDataSource;

  KhataRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> addCustomer(CustomerEntity customer) async {
    final model = CustomerModel(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      type: customer.type,
      totalBalance: customer.totalBalance,
      createdAt: customer.createdAt,
    );
    await remoteDataSource.addCustomer(model);
  }

  @override
  Future<List<CustomerEntity>> getAllCustomers() async {
    // Cloud se saare customers le kar aana
    return await remoteDataSource.getAllCustomers();
  }

  @override
  Future<void> addKhataEntry(KhataEntryEntity entry) async {
    final model = KhataEntryModel(
      id: entry.id,
      customerId: entry.customerId,
      amount: entry.amount,
      type: entry.type,
      notes: entry.notes,
      date: entry.date,
    );
    await remoteDataSource.addKhataEntry(model);
  }

  @override
  Future<List<KhataEntryEntity>> getEntriesForCustomer(String customerId) async {
    // Kisi specific customer ki ledger entries cloud se mangwana
    return await remoteDataSource.getEntriesForCustomer(customerId);
  }

  @override
  Future<void> updateCustomerBalance(String customerId, double newBalance) async {
    // Balance update cloud par sync karna
    await remoteDataSource.updateCustomerBalance(customerId, newBalance);
  }
}