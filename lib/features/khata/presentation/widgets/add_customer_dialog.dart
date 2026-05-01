import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/customer_entity.dart';
import '../state/state/khata_provider.dart';

class AddCustomerDialog extends ConsumerStatefulWidget {
  final CustomerEntity? existingCustomer; // 🚀 Added for Edit Mode

  const AddCustomerDialog({super.key, this.existingCustomer});

  @override
  ConsumerState<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<AddCustomerDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    // 🚀 Load existing data if editing, else empty
    _nameController = TextEditingController(text: widget.existingCustomer?.name ?? '');
    _phoneController = TextEditingController(text: widget.existingCustomer?.phone ?? '');
    _selectedType = widget.existingCustomer?.type ?? 'customer';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.existingCustomer != null;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
            isEditMode ? 'Edit Contact' : 'New Contact',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField(_nameController, 'Full Name', Icons.person_outline),
            const SizedBox(height: 16),
            _buildField(_phoneController, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'customer', child: Text('Customer')),
                DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
              ],
              onChanged: (val) => setState(() => _selectedType = val!),
              decoration: _inputDecoration('Type', Icons.category_outlined),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isEditMode ? Colors.blue.shade700 : const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
                if (isEditMode) {
                  // 🚀 UPDATE LOGIC (Requires copyWith in Entity)
                  final updatedCustomer = widget.existingCustomer!.copyWith(
                    name: _nameController.text.trim(),
                    phone: _phoneController.text.trim(),
                    type: _selectedType,
                  );
                  await ref.read(customerProvider.notifier).updateCustomer(updatedCustomer);
                } else {
                  // 🚀 ADD LOGIC
                  final newCustomer = CustomerEntity(
                    id: const Uuid().v4(),
                    name: _nameController.text.trim(),
                    phone: _phoneController.text.trim(),
                    type: _selectedType,
                    createdAt: DateTime.now(),
                    totalBalance: 0.0,
                  );
                  await ref.read(customerProvider.notifier).addCustomer(newCustomer);
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditMode ? 'Contact updated' : 'Contact saved'),
                      backgroundColor: isEditMode ? Colors.blue : const Color(0xFF10B981),
                    ),
                  );
                }
              }
            },
            child: Text(
                isEditMode ? 'Update Contact' : 'Save Contact',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}