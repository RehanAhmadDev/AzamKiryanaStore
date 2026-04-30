// lib/features/pos/utils/pdf_generator.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';

class ReceiptPdfGenerator {

  // --- 🛠️ PDF BANANE KA ASAL LOGIC ---
  static Future<pw.Document> _buildPdf(Map<String, dynamic> sale) async {
    final pdf = pw.Document();

    final String shortId = sale['id'].toString().substring(0, 8).toUpperCase();
    final bool isCash = sale['sale_type'] == 'cash';

    // 🚀 Update: Customer ka actual naam fetch kar raha hai (agar Khata sale ho)
    final String customerName = sale['customers']?['name'] ?? 'Walk-in Customer';

    final DateTime date = DateTime.parse(sale['created_at']).toLocal();
    final String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    final double totalAmount = (sale['total_amount'] as num).toDouble();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'AZAM KIRYANA STORE',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Quality Kiryana & General Store',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: isCash ? PdfColors.green50 : PdfColors.orange50,
                        border: pw.Border.all(color: isCash ? PdfColors.green900 : PdfColors.orange900, width: 1.5),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Text(
                        isCash ? 'CASH RECEIPT' : 'KHATA (UDHAAR) RECEIPT',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold,
                            color: isCash ? PdfColors.green900 : PdfColors.orange900),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // --- INVOICE INFO ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Receipt #: INV-$shortId', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: $formattedDate', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: isCash ? PdfColors.green100 : PdfColors.red100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      isCash ? 'PAID' : 'UNPAID',
                      style: pw.TextStyle(
                        color: isCash ? PdfColors.green800 : PdfColors.red800,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // --- CUSTOMER INFO ---
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CUSTOMER INFORMATION', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    // 🚀 Update: Ab yahan database se uthaya gaya naam nazar aayega
                    pw.Text('Name: $customerName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // --- ITEMS TABLE ---
              pw.TableHelper.fromTextArray(
                headers: ['ITEM DESCRIPTION', 'QTY', 'TOTAL'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellStyle: const pw.TextStyle(fontSize: 11),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                },
                data: [
                  ['General Grocery / Various Items', '${sale['items_count']} Items', 'Rs. ${totalAmount.toStringAsFixed(0)}'],
                ],
              ),
              pw.SizedBox(height: 20),

              // --- TOTAL CALCULATION ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 250,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Divider(color: PdfColors.grey400),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 12)),
                            pw.Text('Rs. ${totalAmount.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 12)),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Tax / Adjustments:', style: const pw.TextStyle(fontSize: 12)),
                            pw.Text('Rs. 0', style: const pw.TextStyle(fontSize: 12)),
                          ],
                        ),
                        pw.Divider(color: PdfColors.grey600, thickness: 1.5),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL DUE :', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Rs. ${totalAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // --- FOOTER MESSAGE ---
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    color: PdfColors.grey50,
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('THANK YOU FOR YOUR PURCHASE!', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 4),
                      pw.Text('Please keep this receipt for your records.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('Visit us again at Azam Kiryana Store', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ),
              pw.Spacer(),

              // --- APP WATERMARK ---
              pw.Divider(color: PdfColors.grey300),
              pw.Center(
                child: pw.Text(
                  'Software Developed by Rehan Ahmad | Azam Kiryana App\nGenerated on: $formattedDate',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // --- BUTTON 1: PURANA ANDROID PREVIEW ---
  static Future<void> previewReceipt(Map<String, dynamic> sale) async {
    final pdf = await _buildPdf(sale);
    final String shortId = sale['id'].toString().substring(0, 8).toUpperCase();

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_INV-$shortId',
    );
  }

  // --- BUTTON 2: DIRECT DOWNLOAD ---
  static Future<void> downloadReceiptSilent(Map<String, dynamic> sale) async {
    final pdf = await _buildPdf(sale);
    final String shortId = sale['id'].toString().substring(0, 8).toUpperCase();
    final Uint8List bytes = await pdf.save();

    await FileSaver.instance.saveFile(
      name: 'Invoice_INV-$shortId.pdf',
      bytes: bytes,
      mimeType: MimeType.pdf,
    );
  }
}