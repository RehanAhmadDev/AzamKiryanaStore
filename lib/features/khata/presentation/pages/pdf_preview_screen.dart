// lib/features/khata/presentation/pages/pdf_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:file_saver/file_saver.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/khata_entry_entity.dart';
import '../utils/pdf_generator.dart';

class PdfPreviewScreen extends StatelessWidget {
  final CustomerEntity customer;
  final List<KhataEntryEntity> entries;

  const PdfPreviewScreen({
    super.key,
    required this.customer,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // App theme consistency
      appBar: AppBar(
        // 🚀 EXPLICIT BACK BUTTON
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Ledger Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // 🚀 DESKTOP FIX: PDF Viewport constrained (slightly wider at 1000px for document reading)
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: PdfPreview(
            build: (format) => PdfGenerator.generateLedgerPdf(customer, entries),
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            pdfFileName: 'Ledger_${customer.name.replaceAll(" ", "_")}.pdf',
            actions: [
              PdfPreviewAction(
                icon: const Icon(Icons.file_download, color: Colors.white),
                onPressed: (context, build, pageFormat) async {
                  try {
                    final bytes = await build(pageFormat);

                    // 🚀 FIXED: 'ext' parameter removed, extension added to 'name'
                    await FileSaver.instance.saveFile(
                      name: 'Ledger_${customer.name.replaceAll(" ", "_")}.pdf',
                      bytes: bytes,
                      mimeType: MimeType.pdf,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report downloaded successfully!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}