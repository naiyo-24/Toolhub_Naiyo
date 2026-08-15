import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PdfEraserScreen extends StatefulWidget {
  final Uint8List imageBytes;
  
  const PdfEraserScreen({super.key, required this.imageBytes});

  @override
  State<PdfEraserScreen> createState() => _PdfEraserScreenState();
}

class _PdfEraserScreenState extends State<PdfEraserScreen> {
  ui.Image? _backgroundImage;
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  double _brushSize = 30.0;
  bool _isSaving = false;
  
  // Optional: Allow the user to disable scrolling when drawing
  bool _isDrawingMode = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _backgroundImage = frame.image;
    });
  }

  Future<void> _saveAndReturn() async {
    if (_backgroundImage == null) return;
    setState(() => _isSaving = true);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(_backgroundImage!.width.toDouble(), _backgroundImage!.height.toDouble());
    
    // Draw original image
    canvas.drawImage(_backgroundImage!, Offset.zero, Paint());

    // Draw white strokes
    final paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = _brushSize;

    for (final stroke in _strokes) {
      if (stroke.length > 1) {
        for (int i = 0; i < stroke.length - 1; i++) {
          canvas.drawLine(stroke[i], stroke[i + 1], paint);
        }
      } else if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, _brushSize / 2, paint..style = PaintingStyle.fill);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (mounted) {
      Navigator.pop(context, byteData?.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_backgroundImage == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Eraser Tool'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
          if (_isSaving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _saveAndReturn),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              panEnabled: !_isDrawingMode,
              scaleEnabled: true, // Always allow pinch-to-zoom
              child: Center(
                child: AspectRatio(
                  aspectRatio: _backgroundImage!.width / _backgroundImage!.height,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scaleX = _backgroundImage!.width / constraints.maxWidth;
                      final scaleY = _backgroundImage!.height / constraints.maxHeight;

                      return GestureDetector(
                        onPanStart: _isDrawingMode ? (details) {
                          setState(() {
                            _currentStroke = [
                              Offset(details.localPosition.dx * scaleX, details.localPosition.dy * scaleY)
                            ];
                            _strokes.add(_currentStroke);
                          });
                        } : null,
                        onPanUpdate: _isDrawingMode ? (details) {
                          setState(() {
                            _strokes.last.add(
                              Offset(details.localPosition.dx * scaleX, details.localPosition.dy * scaleY)
                            );
                          });
                        } : null,
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _EraserPainter(
                            image: _backgroundImage!,
                            strokes: _strokes,
                            brushSize: _brushSize,
                          ),
                        ),
                      );
                    }
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDrawingMode ? Colors.purple : Colors.grey[800],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => setState(() => _isDrawingMode = true),
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text('Erase'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_isDrawingMode ? Colors.blue : Colors.grey[800],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => setState(() => _isDrawingMode = false),
                      icon: const Icon(Icons.pan_tool),
                      label: const Text('Move/Zoom'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.white, size: 12),
                    Expanded(
                      child: Slider(
                        value: _brushSize,
                        min: 5.0,
                        max: 150.0,
                        activeColor: Colors.purple,
                        onChanged: (val) => setState(() => _brushSize = val),
                      ),
                    ),
                    const Icon(Icons.circle, color: Colors.white, size: 24),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EraserPainter extends CustomPainter {
  final ui.Image image;
  final List<List<Offset>> strokes;
  final double brushSize;

  _EraserPainter({required this.image, required this.strokes, required this.brushSize});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw original image to fit the container
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint());

    // Scale strokes from image coordinates back to screen coordinates for rendering
    final scaleX = size.width / image.width;
    final scaleY = size.height / image.height;

    final paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length > 1) {
        paint.strokeWidth = brushSize * ((scaleX + scaleY) / 2);
        for (int i = 0; i < stroke.length - 1; i++) {
          final p1 = Offset(stroke[i].dx * scaleX, stroke[i].dy * scaleY);
          final p2 = Offset(stroke[i + 1].dx * scaleX, stroke[i + 1].dy * scaleY);
          canvas.drawLine(p1, p2, paint);
        }
      } else if (stroke.length == 1) {
        paint.style = PaintingStyle.fill;
        final p = Offset(stroke.first.dx * scaleX, stroke.first.dy * scaleY);
        canvas.drawCircle(p, (brushSize * scaleX) / 2, paint);
        paint.style = PaintingStyle.stroke; // reset
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EraserPainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.brushSize != brushSize;
  }
}
