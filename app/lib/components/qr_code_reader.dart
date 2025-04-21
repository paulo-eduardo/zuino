import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';

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
  Rect? detectedCodeRect;

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
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: hasDetectedCode ? Colors.green : Colors.white,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: hasDetectedCode ? 8 : 3,
              cutOutSize: hasDetectedCode ? 320 : 300,
              cutOutBottomOffset: 0,
              overlayColor: Colors.black.withOpacity(0.7),
            ),
          ),
          // Animated scanning line
          if (!hasDetectedCode)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Center(
                  child: Container(
                    width: 300 * _animation.value,
                    height: 300 * _animation.value,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          // iOS-style scanning indicator
          if (!hasDetectedCode)
            Center(
              child: Container(
                width: 300,
                height: 300,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white.withOpacity(0.8),
                      size: 40,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Posicione o QR Code no centro",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Flash button
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.1,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: FloatingActionButton(
              onPressed: _toggleFlash,
              backgroundColor: Colors.white,
              child: Icon(
                isFlashOn ? Icons.flashlight_off : Icons.flashlight_on,
                color: Colors.black,
                size: 30,
              ),
            ),
          ),
          // Close button (iOS style)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
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

          // Visual feedback animation
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            setState(() {
              // Simulate "locking onto" the QR code
              detectedCodeRect = Rect.fromCenter(
                center: Offset(
                  MediaQuery.of(context).size.width / 2,
                  MediaQuery.of(context).size.height / 2,
                ),
                width: 320,
                height: 320,
              );
            });
          });

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
