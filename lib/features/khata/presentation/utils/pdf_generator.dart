// lib/features/khata/presentation/utils/pdf_generator.dart

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/khata_entry_entity.dart';

class PdfGenerator {
  static Future<Uint8List> generateLedgerPdf(
      CustomerEntity customer, List<KhataEntryEntity> entries) async {
    final pdf = pw.Document();
    final bool isReceivable = customer.totalBalance >= 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // --- HEADER ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('AZAM KIRYANA STORE',
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('Customer Ledger Report', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
                pw.Text(DateFormat('dd-MMM-yyyy').format(DateTime.now())),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),

            // --- CUSTOMER SUMMARY CARD ---
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                // 🚀 FIXED: pw.Start ko pw.CrossAxisAlignment.start se replace kiya
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Customer Name: ${customer.name}',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text('Phone: ${customer.phone ?? "N/A"}', style: const pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Net Balance Status:', style: const pw.TextStyle(fontSize: 14)),
                      pw.Text(
                        'Rs. ${customer.totalBalance.abs().toStringAsFixed(0)} ${isReceivable ? "(Receivable)" : "(Payable)"}',
                        style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: isReceivable ? PdfColors.green700 : PdfColors.red700
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),
            pw.Text('Transaction History',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
            pw.SizedBox(height: 10),

            // --- TRANSACTIONS TABLE ---
            if (entries.isEmpty)
              pw.Center(child: pw.Text('No transactions found.', style: const pw.TextStyle(color: PdfColors.grey)))
            else
              pw.TableHelper.fromTextArray(
                context: context,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellHeight: 25,
                columnWidths: {
                  0: const pw.FixedColumnWidth(80),
                  1: const pw.FlexColumnWidth(),
                  2: const pw.FixedColumnWidth(60),
                  3: const pw.FixedColumnWidth(80),
                },
                headers: ['Date', 'Details/Notes', 'Type', 'Amount'],
                data: entries.map((e) {
                  return [
                    DateFormat('dd-MM-yyyy').format(e.date),
                    e.notes ?? '-',
                    e.type.name.toUpperCase(),
                    'Rs. ${e.amount.toStringAsFixed(0)}',
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 40),
            pw.Divider(color: PdfColors.grey200),
            pw.Center(
              child: pw.Text('This is a computer-generated report by Azam Kiryana App.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}