// lib/features/pos/presentation/pages/invoices_receipts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/pdf_generator.dart';


class InvoicesReceiptsScreen extends ConsumerStatefulWidget {
  const InvoicesReceiptsScreen({super.key});

  @override
  ConsumerState<InvoicesReceiptsScreen> createState() => _InvoicesReceiptsScreenState();
}

class _InvoicesReceiptsScreenState extends ConsumerState<InvoicesReceiptsScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _sales = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  Future<void> _fetchSales() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('sales')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _sales = response;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sales: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String isoString) {
    DateTime date = DateTime.parse(isoString).toLocal();
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showReceiptDetails(Map<String, dynamic> sale) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long, size: 48, color: Color(0xFF0F172A)),
                    const SizedBox(height: 16),
                    const Text('Receipt Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Invoice: #INV-${sale['id'].toString().substring(0, 8).toUpperCase()}',
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                    const Divider(height: 32),

                    _buildReceiptRow('Items Count:', '${sale['items_count']} Items'),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Sale Type:', sale['sale_type'].toString().toUpperCase()),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Date:', _formatDate(sale['created_at'])),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: _buildReceiptRow(
                        'Total Bill:',
                        'Rs. ${(sale['total_amount'] as num).toStringAsFixed(0)}',
                        isTotal: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- 🚀 NAYE DONO BUTTONS ---
                    Row(
                      children: [
                        // Button 1: Direct Download
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              Navigator.pop(context); // Close dialog
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading Bill...')));
                              await ReceiptPdfGenerator.downloadReceiptSilent(sale);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Downloads!'), backgroundColor: Color(0xFF10B981)));
                            },
                            icon: const Icon(Icons.download, color: Color(0xFF10B981), size: 18),
                            label: const Text('Download', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Button 2: Android Preview
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              Navigator.pop(context); // Close dialog
                              await ReceiptPdfGenerator.previewReceipt(sale);
                            },
                            icon: const Icon(Icons.visibility, color: Colors.white, size: 18),
                            label: const Text('Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- 🚀 CLOSE (X) BUTTON TOP RIGHT PAR ---
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? const Color(0xFF0F172A) : Colors.grey.shade700,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSales = _sales.where((sale) {
      final idString = sale['id'].toString().toLowerCase();
      return idString.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Invoices & Receipts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by Invoice ID...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : RefreshIndicator(
              onRefresh: _fetchSales,
              child: filteredSales.isEmpty
                  ? ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Text('No receipts found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                ],
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredSales.length,
                itemBuilder: (context, index) {
                  final sale = filteredSales[index];
                  final isCash = sale['sale_type'] == 'cash';
                  final shortId = sale['id'].toString().substring(0, 8).toUpperCase();

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showReceiptDetails(sale),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCash ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.receipt_outlined,
                                color: isCash ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '#INV-$shortId',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isCash ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFF3B82F6).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isCash ? 'CASH' : 'KHATA',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isCash ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDate(sale['created_at']),
                                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                      Text(
                                        'Rs. ${(sale['total_amount'] as num).toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}