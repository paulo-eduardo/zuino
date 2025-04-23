import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'qr_scanner_overlay.dart';

class QRCodeReader extends StatefulWidget {
  const QRCodeReader({super.key});

  @override
  State<QRCodeReader> createState() => _QRCodeReaderState();
}

class _QRCodeReaderState extends State<QRCodeReader>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  bool isFlashOn = false;
  bool hasDetectedCode = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // QR Scanner Camera View
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
          ),

          // Custom Overlay Widget
          QrScannerOverlay(
            isFlashOn: isFlashOn,
            onFlashToggle: _toggleFlash,
            onClose: () => Navigator.pop(context),
          ),

          // Test button with hardcoded QR code
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton(
              backgroundColor: Colors.blue,
              child: const Icon(Icons.code),
              onPressed: () {
                // Return the hardcoded QR code
                Navigator.pop(
                  context,
                  "https://www.fazenda.pr.gov.br/nfce/qrcode?p=41250378119914000163650110000614801218655593%7C2%7C1%7C3%7C7B387592EDB47C7777D56760BD0F7E268B05A39A",
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (!mounted) return;

    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String code = barcodes.first.rawValue!;

      setState(() {
        hasDetectedCode = true;
        _animationController.stop();
      });

      // Play success haptic feedback
      HapticFeedback.mediumImpact();

      // Return the scanned data after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context, code);
        }
      });
    }
  }

  void _toggleFlash() {
    controller.toggleTorch();
    setState(() {
      isFlashOn = !isFlashOn;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }
}
