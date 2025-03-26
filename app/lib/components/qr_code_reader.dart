import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';

class QRCodeReader extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRCodeReaderState();
}

class _QRCodeReaderState extends State<QRCodeReader> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = true;
  Color borderColor = Colors.white;
  bool isFlashOn = false;

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
              borderColor: borderColor,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
              overlayColor: Colors.black.withOpacity(0.8), // Semi-transparent overlay
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.1, // Adjust the bottom position dynamically
            left: MediaQuery.of(context).size.width / 2 - 28, // Adjust the left position dynamically
            child: FloatingActionButton(
              onPressed: _toggleFlash,
              backgroundColor: Colors.white,
              child: Icon(
                isFlashOn ? Icons.flashlight_off : Icons.flashlight_on, // Use flashlight icons
                color: Colors.black,
                size: 30,
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
    controller.scannedDataStream.listen((scanData) {
      if (!mounted) return;
      setState(() {
        borderColor = Colors.green;
        isScanning = false;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context, scanData.code);
        }
      });
    }, onError: (error) {
      if (!mounted) return;
      setState(() {
        borderColor = Colors.red;
      });
    });
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
    controller?.dispose();
    super.dispose();
  }
}
