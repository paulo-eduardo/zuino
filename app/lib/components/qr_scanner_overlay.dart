import 'package:flutter/material.dart';
import 'dart:math' as Math;

class QrScannerOverlay extends StatelessWidget {
  final bool isFlashOn;
  final VoidCallback onFlashToggle;
  final VoidCallback onClose;

  const QrScannerOverlay({
    Key? key,
    required this.isFlashOn,
    required this.onFlashToggle,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate a more appropriate size for the scanning area
    // Making it smaller and ensuring it's square
    final scanSize = MediaQuery.of(context).size.width * 0.65;

    return Stack(
      children: [
        // Scanning Area with Corner Brackets
        Center(
          child: Container(
            width: scanSize,
            height: scanSize,
            child: CustomPaint(painter: CornerBracketsPainter()),
          ),
        ),

        // Instruction Text with dark background
        Positioned(
          top: MediaQuery.of(context).size.height * 0.17,
          left: 0,
          right: 0,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 50),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Aponte ao código para escanear",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Flash button
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: MediaQuery.of(context).size.width / 2 - 28,
          child: FloatingActionButton(
            onPressed: onFlashToggle,
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
            onTap: onClose,
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
    );
  }
}

class CornerBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0
          ..strokeCap =
              StrokeCap.round; // Round caps for the tips of the corners

    // Bracket length - about 15% of the width
    final double bracketLength = size.width * 0.15;

    // Control point distance for the squared parts
    final double controlPointDistance = size.width * 0.07;

    // Top-left corner - squared with rounded tip
    final Path topLeftPath =
        Path()
          ..moveTo(bracketLength, 0)
          ..lineTo(controlPointDistance, 0) // Straight line
          ..quadraticBezierTo(0, 0, 0, controlPointDistance) // Rounded corner
          ..lineTo(0, bracketLength);
    canvas.drawPath(topLeftPath, paint);

    // Top-right corner - squared with rounded tip
    final Path topRightPath =
        Path()
          ..moveTo(size.width - bracketLength, 0)
          ..lineTo(size.width - controlPointDistance, 0) // Straight line
          ..quadraticBezierTo(
            size.width,
            0,
            size.width,
            controlPointDistance,
          ) // Rounded corner
          ..lineTo(size.width, bracketLength);
    canvas.drawPath(topRightPath, paint);

    // Bottom-left corner - squared with rounded tip
    final Path bottomLeftPath =
        Path()
          ..moveTo(0, size.height - bracketLength)
          ..lineTo(0, size.height - controlPointDistance) // Straight line
          ..quadraticBezierTo(
            0,
            size.height,
            controlPointDistance,
            size.height,
          ) // Rounded corner
          ..lineTo(bracketLength, size.height);
    canvas.drawPath(bottomLeftPath, paint);

    // Bottom-right corner - squared with rounded tip
    final Path bottomRightPath =
        Path()
          ..moveTo(size.width, size.height - bracketLength)
          ..lineTo(
            size.width,
            size.height - controlPointDistance,
          ) // Straight line
          ..quadraticBezierTo(
            size.width,
            size.height,
            size.width - controlPointDistance,
            size.height,
          ) // Rounded corner
          ..lineTo(size.width - bracketLength, size.height);
    canvas.drawPath(bottomRightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
