// lib/features/khata/presentation/pages/pdf_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🚀 Added Riverpod
import 'package:printing/printing.dart';
import 'package:file_saver/file_saver.dart';
import '../../../../core/theme/theme_provider.dart'; // 🚀 Theme Provider Import
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/khata_entry_entity.dart';
import '../utils/pdf_generator.dart';

class PdfPreviewScreen extends ConsumerWidget {
  final CustomerEntity customer;
  final List<KhataEntryEntity> entries;

  const PdfPreviewScreen({
    super.key,
    required this.customer,
    required this.entries,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 Theme State Watch
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Ledger Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: themeState.primaryColor, // 🚀 Dynamic Theme Color
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          // 🚀 DESKTOP WIDTH FIX: 1200px for better document viewing
          constraints: const BoxConstraints(maxWidth: 1200),
          child: PdfPreview(
            build: (format) => PdfGenerator.generateLedgerPdf(customer, entries),
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            // 🚀 PDF Controls color sync with theme
            loadingWidget: CircularProgressIndicator(color: themeState.primaryColor),
            pdfFileName: 'Ledger_${customer.name.replaceAll(" ", "_")}.pdf',
            actions: [
              PdfPreviewAction(
                icon: const Icon(Icons.file_download, color: Colors.white),
                onPressed: (context, build, pageFormat) async {
                  try {
                    final bytes = await build(pageFormat);

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