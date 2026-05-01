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
    try {
      final model = CustomerModel(
        id: customer.id,
        name: customer.name,
        phone: customer.phone,
        type: customer.type,
        totalBalance: customer.totalBalance,
        createdAt: customer.createdAt,
      );
      await remoteDataSource.addCustomer(model);
    } catch (e) {
      throw Exception('Failed to add customer: $e');
    }
  }

  // 🚀 NEW: Update Customer Name/Phone Implementation
  @override
  Future<void> updateCustomer(CustomerEntity customer) async {
    try {
      final model = CustomerModel(
        id: customer.id,
        name: customer.name,
        phone: customer.phone,
        type: customer.type,
        totalBalance: customer.totalBalance,
        createdAt: customer.createdAt,
      );
      await remoteDataSource.updateCustomer(model);
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  @override
  Future<List<CustomerEntity>> getAllCustomers() async {
    try {
      return await remoteDataSource.getAllCustomers();
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  @override
  Future<void> addKhataEntry(KhataEntryEntity entry) async {
    try {
      final model = KhataEntryModel(
        id: entry.id,
        customerId: entry.customerId,
        amount: entry.amount,
        type: entry.type,
        notes: entry.notes,
        date: entry.date,
      );
      await remoteDataSource.addKhataEntry(model);
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  @override
  Future<List<KhataEntryEntity>> getKhataEntriesByCustomerId(String customerId) async {
    try {
      return await remoteDataSource.getKhataEntriesByCustomerId(customerId);
    } catch (e) {
      throw Exception('Failed to load transaction history: $e');
    }
  }

  @override
  Future<void> updateCustomerBalance(String customerId, double newBalance) async {
    try {
      await remoteDataSource.updateCustomerBalance(customerId, newBalance);
    } catch (e) {
      throw Exception('Failed to update balance: $e');
    }
  }

  @override
  Future<void> deleteKhataEntry(String id) async {
    try {
      await remoteDataSource.deleteKhataEntry(id);
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    try {
      await remoteDataSource.deleteCustomer(customerId);
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  @override
  Future<void> updateKhataEntry(KhataEntryEntity entry) async {
    try {
      final model = KhataEntryModel(
        id: entry.id,
        customerId: entry.customerId,
        amount: entry.amount,
        type: entry.type,
        notes: entry.notes,
        date: entry.date,
      );
      await remoteDataSource.updateKhataEntry(model);
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }
}