import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/theme_provider.dart'; // 🚀 Theme Provider Import
import '../../domain/entities/customer_entity.dart';
import '../state/state/khata_provider.dart';

class AddCustomerDialog extends ConsumerStatefulWidget {
  final CustomerEntity? existingCustomer;

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
    final themeState = ref.watch(themeProvider); // 🚀 Theme State Watch

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Center( // 🚀 Center for Desktop alignment
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450), // 🚀 Professional Dialog Width
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
                isEditMode ? 'Edit Contact' : 'New Contact',
                style: TextStyle(fontWeight: FontWeight.bold, color: themeState.primaryColor) // 🚀 Dynamic Title
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildField(_nameController, 'Full Name', Icons.person_outline, themeState.primaryColor),
                  const SizedBox(height: 16),
                  _buildField(_phoneController, 'Phone Number', Icons.phone_outlined, themeState.primaryColor, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    items: const [
                      DropdownMenuItem(value: 'customer', child: Text('Customer')),
                      DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
                    ],
                    onChanged: (val) => setState(() => _selectedType = val!),
                    decoration: _inputDecoration('Type', Icons.category_outlined, themeState.primaryColor),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeState.primaryColor, // 🚀 Dynamic Theme Button
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
                    if (isEditMode) {
                      final updatedCustomer = widget.existingCustomer!.copyWith(
                        name: _nameController.text.trim(),
                        phone: _phoneController.text.trim(),
                        type: _selectedType,
                      );
                      await ref.read(customerProvider.notifier).updateCustomer(updatedCustomer);
                    } else {
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
                          backgroundColor: themeState.primaryColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                    isEditMode ? 'Update' : 'Save Contact',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, Color primaryColor, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon, primaryColor),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, Color primaryColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
      prefixIcon: Icon(icon, size: 20, color: primaryColor.withOpacity(0.6)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}