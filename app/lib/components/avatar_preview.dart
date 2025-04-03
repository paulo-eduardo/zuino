import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class AvatarPreview extends StatefulWidget {
  final File imageFile;
  final void Function(File croppedFile) onSave;

  const AvatarPreview({Key? key, required this.imageFile, required this.onSave})
    : super(key: key);

  @override
  _AvatarPreviewState createState() => _AvatarPreviewState();
}

class _AvatarPreviewState extends State<AvatarPreview> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  Offset _initialFocalPoint = Offset.zero;
  Offset _initialOffset = Offset.zero;
  double _initialScale = 1.0;

  final GlobalKey _boundaryKey = GlobalKey();

  Future<File> _captureCroppedImage() async {
    // Delay to capture latest frame.
    await Future.delayed(const Duration(milliseconds: 100));
    RenderRepaintBoundary boundary =
        _boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    ui.Image fullImage = await boundary.toImage(
      pixelRatio: ui.window.devicePixelRatio,
    );

    // Define crop size in pixels based on 350 logical pixels.
    final cropSize = (350 * ui.window.devicePixelRatio).toInt();
    final fullWidth = fullImage.width;
    final fullHeight = fullImage.height;
    final cropRect = Rect.fromCenter(
      center: Offset(fullWidth / 2, fullHeight / 2),
      width: cropSize.toDouble(),
      height: cropSize.toDouble(),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final dstRect = Rect.fromLTWH(0, 0, cropRect.width, cropRect.height);
    canvas.drawImageRect(fullImage, cropRect, dstRect, Paint());
    ui.Image croppedImage = await recorder.endRecording().toImage(
      cropSize,
      cropSize,
    );
    ByteData? byteData = await croppedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final pngBytes = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final file = await File(
      '${tempDir.path}/avatar_preview.png',
    ).writeAsBytes(pngBytes);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preview Avatar")),
      body: Stack(
        children: [
          Center(
            child: RepaintBoundary(
              key: _boundaryKey,
              child: Stack(
                children: [
                  // Full image with pan and zoom.
                  Positioned.fill(
                    child: GestureDetector(
                      onScaleStart: (details) {
                        _initialFocalPoint = details.focalPoint;
                        _initialOffset = _offset;
                        _initialScale = _scale;
                      },
                      onScaleUpdate: (details) {
                        setState(() {
                          _scale = _initialScale * details.scale;
                          final Offset delta =
                              details.focalPoint - _initialFocalPoint;
                          _offset = _initialOffset + delta;
                        });
                      },
                      child: Transform(
                        alignment: Alignment.center,
                        transform:
                            Matrix4.identity()
                              ..translate(_offset.dx, _offset.dy)
                              ..scale(_scale),
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  // Overlay mask showing crop circle.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: CropCirclePainter()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Floating save button under the aim circle.
          Align(
            alignment: const Alignment(
              0,
              0.7,
            ), // adjust vertical alignment as needed
            child: FloatingActionButton(
              onPressed: () async {
                File croppedFile = await _captureCroppedImage();
                widget.onSave(croppedFile);
              },
              child: const Icon(Icons.save),
            ),
          ),
        ],
      ),
    );
  }
}

class CropCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.5);
    // Create a full-rectangle path.
    final rectPath = Path()..addRect(Offset.zero & size);
    // Update circle radius to half of 350 logical pixels.
    final circleRadius = 175.0;
    final center = size.center(Offset.zero);
    final circlePath =
        Path()..addOval(Rect.fromCircle(center: center, radius: circleRadius));
    // Subtract the circle from the rectangle.
    final finalPath = Path.combine(
      PathOperation.difference,
      rectPath,
      circlePath,
    );
    canvas.drawPath(finalPath, overlayPaint);

    // Draw border around the circle.
    final borderPaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(center, circleRadius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
