import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/khata_entry_entity.dart';
import '../models/customer_model.dart';
import '../models/khata_entry_model.dart';

abstract class KhataRemoteDataSource {
  Future<void> addCustomer(CustomerModel customer);
  Future<List<CustomerModel>> getAllCustomers();
  Future<void> addKhataEntry(KhataEntryModel entry);
  Future<List<KhataEntryModel>> getEntriesForCustomer(String customerId);
  Future<void> updateCustomerBalance(String customerId, double newBalance);
}

class KhataSupabaseDataSourceImpl implements KhataRemoteDataSource {
  // Supabase client ka instance
  final _supabase = Supabase.instance.client;

  @override
  Future<void> addCustomer(CustomerModel customer) async {
    // Supabase DB mein snake_case columns use kiye hain, is liye hum directly map kar rahe hain
    await _supabase.from('customers').insert({
      'id': customer.id,
      'name': customer.name,
      'phone': customer.phone,
      'type': customer.type,
      'total_balance': customer.totalBalance,
      'created_at': customer.createdAt.toIso8601String(),
    });
  }

  @override
  Future<List<CustomerModel>> getAllCustomers() async {
    final List<dynamic> response = await _supabase
        .from('customers')
        .select()
        .order('created_at', ascending: false);

    // Supabase response ko apne Dart Model mein convert kar rahe hain
    return response.map((map) => CustomerModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      type: map['type'],
      totalBalance: (map['total_balance'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at']),
    )).toList();
  }

  @override
  Future<void> addKhataEntry(KhataEntryModel entry) async {
    // 1. Entry ko save karna
    await _supabase.from('khata_entries').insert({
      'id': entry.id,
      'customer_id': entry.customerId,
      'amount': entry.amount,
      'type': entry.type == EntryType.gave ? 'gave' : 'got',
      'notes': entry.notes,
      'date': entry.date.toIso8601String(),
    });

    // 2. Customer ka current balance Cloud se get karna
    final customerData = await _supabase
        .from('customers')
        .select('total_balance')
        .eq('id', entry.customerId)
        .single();

    if (customerData.isNotEmpty) {
      double currentBalance = (customerData['total_balance'] as num).toDouble();

      // Lene hain (+ve), Dene hain (-ve)
      double amountImpact = entry.type == EntryType.gave ? entry.amount : -entry.amount;
      double newBalance = currentBalance + amountImpact;

      // 3. Updated balance Cloud par save karna
      await _supabase
          .from('customers')
          .update({'total_balance': newBalance})
          .eq('id', entry.customerId);
    }
  }

  @override
  Future<List<KhataEntryModel>> getEntriesForCustomer(String customerId) async {
    final List<dynamic> response = await _supabase
        .from('khata_entries')
        .select()
        .eq('customer_id', customerId)
        .order('date', ascending: false);

    return response.map((map) => KhataEntryModel(
      id: map['id'],
      customerId: map['customer_id'],
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] == 'gave' ? EntryType.gave : EntryType.got,
      notes: map['notes'],
      date: DateTime.parse(map['date']),
    )).toList();
  }

  @override
  Future<void> updateCustomerBalance(String customerId, double newBalance) async {
    await _supabase
        .from('customers')
        .update({'total_balance': newBalance})
        .eq('id', customerId);
  }
}