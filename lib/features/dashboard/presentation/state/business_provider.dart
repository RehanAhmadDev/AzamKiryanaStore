import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessSettings {
  final String storeName;
  final String phoneNumber;
  final String address;
  final String currency;

  BusinessSettings({
    required this.storeName,
    required this.phoneNumber,
    required this.address,
    required this.currency,
  });
}

final businessProvider = StateNotifierProvider<BusinessNotifier, BusinessSettings>((ref) {
  return BusinessNotifier();
});

class BusinessNotifier extends StateNotifier<BusinessSettings> {
  BusinessNotifier() : super(BusinessSettings(storeName: 'Loading...', phoneNumber: '', address: '', currency: 'Rs.')) {
    loadSettings();
  }

  final _supabase = Supabase.instance.client;

  Future<void> loadSettings() async {
    try {
      final data = await _supabase.from('business_settings').select().single();
      state = BusinessSettings(
        storeName: data['store_name'] ?? 'My Store',
        phoneNumber: data['phone_number'] ?? '',
        address: data['address'] ?? '',
        currency: data['currency_symbol'] ?? 'Rs.',
      );
    } catch (e) {
      state = BusinessSettings(storeName: 'Azam Kiryana', phoneNumber: '0300-1234567', address: 'Punjab, Pakistan', currency: 'Rs.');
    }
  }

  Future<void> updateSettings(BusinessSettings newSettings) async {
    try {
      await _supabase.from('business_settings').update({
        'store_name': newSettings.storeName,
        'phone_number': newSettings.phoneNumber,
        'address': newSettings.address,
        'currency_symbol': newSettings.currency,
      }).neq('id', '00000000-0000-0000-0000-000000000000');
      state = newSettings;
    } catch (e) {
      print("Update error: $e");
    }
  }
}