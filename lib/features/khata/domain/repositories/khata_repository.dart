import '../entities/customer_entity.dart';
import '../entities/khata_entry_entity.dart';

abstract class KhataRepository {
  Future<void> addCustomer(CustomerEntity customer);
  Future<List<CustomerEntity>> getAllCustomers();
  Future<void> addKhataEntry(KhataEntryEntity entry);
  Future<List<KhataEntryEntity>> getKhataEntriesByCustomerId(String customerId);
  Future<void> updateCustomerBalance(String customerId, double newBalance);
  Future<void> deleteKhataEntry(String id);
  Future<void> deleteCustomer(String customerId);
  Future<void> updateKhataEntry(KhataEntryEntity entry);

  // 🚀 FIXED: Ye line add karne se Provider ka error khatam ho jayega
  Future<void> updateCustomer(CustomerEntity customer);
}