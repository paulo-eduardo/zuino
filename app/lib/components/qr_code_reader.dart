import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';
import 'qr_scanner_overlay.dart';

class QRCodeReader extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRCodeReaderState();
}

class _QRCodeReaderState extends State<QRCodeReader>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = true;
  bool isFlashOn = false;
  bool hasDetectedCode = false;

  // Animation controller for the scanning effect
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // QR Scanner Camera View
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.transparent,
              borderRadius: 0,
              borderLength: 0,
              borderWidth: 0,
              cutOutSize: 300,
              overlayColor: Colors.transparent,
            ),
          ),

          // Custom Overlay Widget
          QrScannerOverlay(
            isFlashOn: isFlashOn,
            onFlashToggle: _toggleFlash,
            onClose: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen(
      (scanData) {
        if (!mounted) return;

        // Get position of the QR code if available
        if (scanData.format != null) {
          setState(() {
            hasDetectedCode = true;
            _animationController.stop();
          });

          // Play success haptic feedback if available
          HapticFeedback.mediumImpact();

          // Return the scanned data after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (!mounted) return;
            if (Navigator.canPop(context)) {
              Navigator.pop(context, scanData.code);
            }
          });
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          hasDetectedCode = false;
        });
      },
    );
  }

  void _toggleFlash() {
    if (controller != null) {
      controller!.toggleFlash();
      setState(() {
        isFlashOn = !isFlashOn;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller?.dispose();
    super.dispose();
  }
}
