import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/khata_entry_entity.dart';

class PdfGenerator {
  // Naya function jo PDF ka data (bytes) return karta hai
  static Future<Uint8List> generateLedgerPdf(
      CustomerEntity customer, List<KhataEntryEntity> entries) async {
    final pdf = pw.Document();
    final bool isReceivable = customer.totalBalance >= 0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Customer Ledger',
                  style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
              pw.SizedBox(height: 20),

              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Name: ${customer.name}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text('Phone: ${customer.phone}', style: const pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Total Balance: Rs. ${customer.totalBalance.abs().toStringAsFixed(0)} (${isReceivable ? "You'll Get" : "You'll Give"})',
                      style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: isReceivable ? PdfColors.green700 : PdfColors.red700
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),
              pw.Text('Transaction History', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 15),

              if (entries.isEmpty)
                pw.Text('No transactions available.', style: const pw.TextStyle(color: PdfColors.grey))
              else
                pw.Table.fromTextArray(
                  context: context,
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                  rowDecoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.all(10),
                  data: <List<String>>[
                    <String>['Date', 'Details', 'Type', 'Amount'],
                    ...entries.map((e) {
                      final isGave = e.type == EntryType.gave;
                      final String details = (e.notes != null && e.notes!.isNotEmpty)
                          ? e.notes!
                          : (isGave ? 'Gave' : 'Got');
                      return [
                        DateFormat('dd MMM yyyy').format(e.date),
                        details,
                        isGave ? 'Gave (DIVE)' : 'Got (LIYE)',
                        'Rs. ${e.amount.toStringAsFixed(0)}',
                      ];
                    }),
                  ],
                ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }
}