import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/khata_entry_entity.dart';
import '../../domain/repositories/khata_repository.dart';
import '../datasources/khata_supabase_data_source.dart';
import '../models/customer_model.dart';
import '../models/khata_entry_model.dart';

class KhataRepositoryImpl implements KhataRepository {
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

  // Method name updated to match the new repository interface
  @override
  Future<List<KhataEntryEntity>> getKhataEntriesByCustomerId(String customerId) async {
    return await remoteDataSource.getKhataEntriesByCustomerId(customerId);
  }

  @override
  Future<void> updateCustomerBalance(String customerId, double newBalance) async {
    await remoteDataSource.updateCustomerBalance(customerId, newBalance);
  }
}