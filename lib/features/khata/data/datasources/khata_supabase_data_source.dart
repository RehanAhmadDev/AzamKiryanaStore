import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/khata_entry_entity.dart';
import '../models/customer_model.dart';
import '../models/khata_entry_model.dart';

abstract class KhataRemoteDataSource {
  Future<void> addCustomer(CustomerModel customer);
  Future<List<CustomerModel>> getAllCustomers();
  Future<void> addKhataEntry(KhataEntryModel entry);
  Future<List<KhataEntryModel>> getKhataEntriesByCustomerId(String customerId);
  Future<void> updateCustomerBalance(String customerId, double newBalance);
  Future<void> deleteKhataEntry(String entryId);
  Future<void> deleteCustomer(String customerId);
  Future<void> updateKhataEntry(KhataEntryModel entry);

  // 🚀 NEW: Update Customer Interface
  Future<void> updateCustomer(CustomerModel customer);
}

class KhataSupabaseDataSourceImpl implements KhataRemoteDataSource {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  @override
  Future<void> addCustomer(CustomerModel customer) async {
    await _supabase.from('customers').insert({
      'id': customer.id.isEmpty ? _uuid.v4() : customer.id,
      'name': customer.name,
      'phone': customer.phone,
      'type': customer.type,
      'total_balance': customer.totalBalance,
      'created_at': customer.createdAt.toIso8601String(),
    });
  }

  // 🚀 NEW: Update Customer Logic (Name & Phone)
  @override
  Future<void> updateCustomer(CustomerModel customer) async {
    await _supabase.from('customers').update({
      'name': customer.name,
      'phone': customer.phone,
    }).eq('id', customer.id);
  }

  @override
  Future<List<CustomerModel>> getAllCustomers() async {
    final List<dynamic> response = await _supabase
        .from('customers')
        .select()
        .order('created_at', ascending: false);

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
    final entryId = entry.id.isEmpty ? _uuid.v4() : entry.id;

    await _supabase.from('khata_entries').insert({
      'id': entryId,
      'customer_id': entry.customerId,
      'amount': entry.amount,
      'type': entry.type == EntryType.gave ? 'gave' : 'got',
      'notes': entry.notes,
      'date': entry.date.toIso8601String(),
    });

    await _syncCustomerBalance(entry.customerId);
  }

  @override
  Future<List<KhataEntryModel>> getKhataEntriesByCustomerId(String customerId) async {
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

  @override
  Future<void> deleteKhataEntry(String entryId) async {
    final entryData = await _supabase
        .from('khata_entries')
        .select('customer_id')
        .eq('id', entryId)
        .single();

    final String customerId = entryData['customer_id'];
    await _supabase.from('khata_entries').delete().eq('id', entryId);
    await _syncCustomerBalance(customerId);
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    await _supabase.from('customers').delete().eq('id', customerId);
  }

  @override
  Future<void> updateKhataEntry(KhataEntryModel entry) async {
    await _supabase.from('khata_entries').update({
      'amount': entry.amount,
      'type': entry.type == EntryType.gave ? 'gave' : 'got',
      'notes': entry.notes,
      'date': entry.date.toIso8601String(),
    }).eq('id', entry.id);

    await _syncCustomerBalance(entry.customerId);
  }

  Future<void> _syncCustomerBalance(String customerId) async {
    final List<dynamic> entries = await _supabase
        .from('khata_entries')
        .select('amount, type')
        .eq('customer_id', customerId);

    double total = 0.0;
    for (var entry in entries) {
      double amt = (entry['amount'] as num).toDouble();
      if (entry['type'] == 'gave') {
        total += amt;
      } else {
        total -= amt;
      }
    }
    await updateCustomerBalance(customerId, total);
  }
}