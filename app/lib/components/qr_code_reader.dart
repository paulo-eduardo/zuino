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
            ),
          ),
          if (!isScanning)
            Center(
              child: Container(
                color: Colors.black54.withOpacity(0.5),
                padding: const EdgeInsets.all(8.0),
                child: const Text(
                  'QR Code Scanned!',
                  style: TextStyle(color: Colors.white, fontSize: 20),
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

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
