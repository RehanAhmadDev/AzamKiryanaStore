// lib/features/inventory/presentation/screens/barcode_scanner_view.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _screenOpened = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🚀 DESKTOP FIX: Dark background taake badi screen par borders achay lagain
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        centerTitle: true,
        elevation: 0,
        // 🚀 EXPLICIT BACK BUTTON
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          // Flashlight Toggle
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.flashlight_on_rounded),
            onPressed: () => cameraController.toggleTorch(),
          ),
          // Camera Switch (Front/Back)
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      // 🚀 DESKTOP FIX: Centered ConstrainedBox so camera doesn't stretch on wide screens
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ClipRRect(
            // Optional: Agar desktop par maxWidth apply ho toh corners rounded honge
            borderRadius: BorderRadius.circular(PlatformUtils.isDesktop(context) ? 24 : 0),
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && !_screenOpened) {
                      _screenOpened = true;
                      final String code = barcodes.first.rawValue ?? "Unknown";
                      Navigator.pop(context, code);
                    }
                  },
                ),
                // Scanner Frame Overlay
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF10B981), width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                // Guidance Text
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Place barcode inside the green frame',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

// Chota sa helper aapke utils mein dalne ke liye ya yahin rakhne ke liye
class PlatformUtils {
  static bool isDesktop(BuildContext context) {
    // Basic check: agar width 600 se zyada hai toh hum isko wide screen consider karte hain
    return MediaQuery.of(context).size.width > 600;
  }
}