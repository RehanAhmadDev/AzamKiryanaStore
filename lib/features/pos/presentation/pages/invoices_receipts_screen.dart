// lib/features/pos/presentation/pages/invoices_receipts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../utils/pdf_generator.dart';
import '../state/pos_provider.dart';

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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('sales')
          .select('*, customers(name)')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _sales = response;
        });
      }
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
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  void _showReceiptDetails(Map<String, dynamic> sale, Color primaryColor) {
    final String customerName = sale['customers']?['name'] ?? 'Walk-in Customer';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
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
                      Icon(Icons.receipt_long, size: 48, color: primaryColor),
                      const SizedBox(height: 16),
                      const Text('Receipt Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        'Invoice: #INV-${sale['id'].toString().substring(0, 8).toUpperCase()}',
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                      const Divider(height: 32),

                      _buildReceiptRow('Customer:', customerName, primaryColor),
                      const SizedBox(height: 8),
                      _buildReceiptRow('Items Count:', '${sale['items_count']} Items', primaryColor),
                      const SizedBox(height: 8),
                      _buildReceiptRow('Sale Type:', sale['sale_type'].toString().toUpperCase(), primaryColor),
                      const SizedBox(height: 8),
                      _buildReceiptRow('Date:', _formatDate(sale['created_at']), primaryColor),
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
                          primaryColor,
                          isTotal: true,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                Navigator.pop(context);
                                await ReceiptPdfGenerator.downloadReceiptSilent(sale);
                              },
                              icon: const Icon(Icons.download, color: Color(0xFF10B981), size: 18),
                              label: const Text('Download', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                Navigator.pop(context);
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
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, Color primaryColor, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? primaryColor : Colors.grey.shade700,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isTotal ? primaryColor : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    final filteredSales = _sales.where((sale) {
      final idString = sale['id'].toString().toLowerCase();
      final customerName = (sale['customers']?['name'] ?? '').toString().toLowerCase();
      return idString.contains(_searchQuery.toLowerCase()) || customerName.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        title: const Text('Invoices & Receipts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: themeState.primaryColor,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200), // 🚀 Flexible width for Desktop
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by Invoice ID or Name...',
                    prefixIcon: Icon(Icons.search, color: themeState.primaryColor.withOpacity(0.5)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeState.primaryColor, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: themeState.primaryColor))
                    : RefreshIndicator(
                  onRefresh: _fetchSales,
                  child: filteredSales.isEmpty
                      ? const Center(child: Text('No receipts found.', style: TextStyle(color: Colors.grey, fontSize: 16)))
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredSales.length,
                    itemBuilder: (context, index) {
                      final sale = filteredSales[index];
                      final isCash = sale['sale_type'] == 'cash';
                      final shortId = sale['id'].toString().substring(0, 8).toUpperCase();
                      final String customerName = sale['customers']?['name'] ?? 'Walk-in Customer';

                      return Dismissible(
                        key: Key(sale['id'].toString()),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) => _showVoidConfirmation(context),
                        onDismissed: (direction) async {
                          await ref.read(productsProvider.notifier).deleteSale(sale['id']);
                          setState(() {
                            _sales.removeWhere((element) => element['id'] == sale['id']);
                          });
                        },
                        background: _buildDeleteBackground(),
                        child: _buildInvoiceCard(sale, shortId, customerName, isCash, themeState.primaryColor),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> sale, String shortId, String customerName, bool isCash, Color primaryColor) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        hoverColor: primaryColor.withOpacity(0.05),
        onTap: () => _showReceiptDetails(sale, primaryColor),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCash ? const Color(0xFF10B981).withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_outlined, color: isCash ? const Color(0xFF10B981) : Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('#INV-$shortId', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor)),
                        _buildStatusBadge(isCash),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF475569))),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDate(sale['created_at']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('Rs. ${(sale['total_amount'] as num).toStringAsFixed(0)}',
                            style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor, fontSize: 16)),
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
  }

  Widget _buildStatusBadge(bool isCash) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCash ? const Color(0xFF10B981).withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isCash ? 'CASH' : 'KHATA',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCash ? const Color(0xFF10B981) : Colors.blue),
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.delete_forever, color: Colors.white, size: 32),
    );
  }

  Future<bool?> _showVoidConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Void Invoice?"),
        content: const Text("Are you sure you want to delete this sale? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}