import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerWidget extends StatelessWidget {
  final Function(String) onDetect;

  const BarcodeScannerWidget({super.key, required this.onDetect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
        ),
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              onDetect(barcode.rawValue!); // Code milte hi wapis bhej dega
              Navigator.pop(context); // Scanner band kar dega
              break;
            }
          }
        },
      ),
    );
  }
}