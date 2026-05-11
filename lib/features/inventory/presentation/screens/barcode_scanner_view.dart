// lib/features/inventory/presentation/screens/barcode_scanner_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🚀 Added Riverpod
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/theme_provider.dart';


class BarcodeScannerView extends ConsumerStatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  ConsumerState<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends ConsumerState<BarcodeScannerView> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _screenOpened = false;

  @override
  Widget build(BuildContext context) {
    // 🚀 Theme watch
    final themeState = ref.watch(themeProvider);
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: themeState.primaryColor, // 🚀 Dynamic Theme Color
        centerTitle: true,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.flashlight_on_rounded),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          // 🚀 DESKTOP FIX: Camera feed constrained for better look
          constraints: const BoxConstraints(maxWidth: 800),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isWideScreen ? 24 : 0),
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
                      // 🚀 Theme aware frame color
                      border: Border.all(color: themeState.primaryColor, width: 4),
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
                        'Place barcode inside the frame',
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