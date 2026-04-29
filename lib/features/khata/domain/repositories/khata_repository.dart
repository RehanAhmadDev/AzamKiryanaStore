import '../entities/customer_entity.dart';
import '../entities/khata_entry_entity.dart';

abstract class KhataRepository {
  // Customers ke methods
  Future<void> addCustomer(CustomerEntity customer);
  Future<List<CustomerEntity>> getAllCustomers();

  // Khata Entries (DIVE/LIYE) ke methods
  Future<void> addKhataEntry(KhataEntryEntity entry);

  // Method name updated to match provider
  Future<List<KhataEntryEntity>> getKhataEntriesByCustomerId(String customerId);

  // Balance update karne ka method
  Future<void> updateCustomerBalance(String customerId, double newBalance);
}