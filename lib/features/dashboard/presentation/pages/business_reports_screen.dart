// lib/features/dashboard/presentation/pages/business_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../inventory/presentation/state/reports_provider.dart';

class BusinessReportsScreen extends ConsumerStatefulWidget {
  const BusinessReportsScreen({super.key});

  @override
  ConsumerState<BusinessReportsScreen> createState() => _BusinessReportsScreenState();
}

class _BusinessReportsScreenState extends ConsumerState<BusinessReportsScreen> {
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    // Screen khulte hi data fetch karein
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).fetchReportData(dateRange: _selectedDateRange);
    });
  }

  // 🚀 PDF Generation Logic: Bilkul Professional Layout
  Future<void> _generatePdfReport(ReportData data, Color primaryColor) async {
    final pdf = pw.Document();
    final themeColor = PdfColor.fromInt(primaryColor.value);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Azam Kiryana Store',
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: themeColor)),
                    pw.Text('Business Report', style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Report Period: ${DateFormat('dd MMM yyyy').format(_selectedDateRange.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange.end)}'),
              pw.SizedBox(height: 20),

              pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 1, color: themeColor),
              pw.SizedBox(height: 10),

              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: themeColor),
                cellAlignment: pw.Alignment.centerLeft,
                data: [
                  ['Category', 'Amount (PKR)'],
                  ['Total Sales', 'Rs. ${data.totalSales.toStringAsFixed(2)}'],
                  ['Gross Profit', 'Rs. ${data.totalProfit.toStringAsFixed(2)}'],
                  ['Total Expenses', 'Rs. ${data.totalExpenses.toStringAsFixed(2)}'],
                  ['Net Take Home', 'Rs. ${data.netProfit.toStringAsFixed(2)}'],
                ],
              ),

              pw.SizedBox(height: 40),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Business_Report_${DateFormat('dd_MMM').format(_selectedDateRange.start)}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final reportsAsync = ref.watch(reportsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: themeState.primaryColor,
        title: const Text('Business Reports',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Date Range Indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                color: themeState.primaryColor.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.date_range, size: 18, color: themeState.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Period: ${DateFormat('dd MMM').format(_selectedDateRange.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange.end)}',
                      style: TextStyle(fontWeight: FontWeight.w600, color: themeState.primaryColor),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: reportsAsync.when(
                  loading: () => Center(child: CircularProgressIndicator(color: themeState.primaryColor)),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (data) => SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSummaryGrid(data, themeState.primaryColor),
                        const SizedBox(height: 30),
                        _buildBreakdownSection(data, themeState.primaryColor),
                        const SizedBox(height: 40),
                        _buildActionButton(
                            'Download PDF Report',
                            Icons.picture_as_pdf,
                            Colors.red.shade700,
                                () => _generatePdfReport(data, themeState.primaryColor)
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(ReportData data, Color primaryColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildInfoCard('Total Sales', 'Rs. ${data.totalSales.toStringAsFixed(0)}', Colors.blue, Icons.shopping_cart),
            _buildInfoCard('Gross Profit', 'Rs. ${data.totalProfit.toStringAsFixed(0)}', Colors.orange, Icons.trending_up),
            _buildInfoCard('Expenses', 'Rs. ${data.totalExpenses.toStringAsFixed(0)}', Colors.red, Icons.money_off),
            _buildInfoCard('Net Profit', 'Rs. ${data.netProfit.toStringAsFixed(0)}', const Color(0xFF10B981), Icons.account_balance_wallet),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(ReportData data, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildDetailRow('Sales Revenue', 'Rs. ${data.totalSales}', Colors.black87),
          const Divider(height: 24),
          _buildDetailRow('Estimated Profit', '+ Rs. ${data.totalProfit}', Colors.green),
          const Divider(height: 24),
          _buildDetailRow('Total Expenses', '- Rs. ${data.totalExpenses}', Colors.red),
          const Divider(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildDetailRow(
                'Actual Take Home (Net)',
                'Rs. ${data.netProfit}',
                primaryColor,
                isBold: true
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: ref.read(themeProvider).primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      ref.read(reportsProvider.notifier).fetchReportData(dateRange: picked);
    }
  }
}