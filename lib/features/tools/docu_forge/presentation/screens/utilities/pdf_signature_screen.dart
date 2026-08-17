import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:signature/signature.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:tool_hub/core/utils/permission_disclosure_utils.dart';
import 'package:tool_hub/core/api/api_config.dart';

class PdfSignatureScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const PdfSignatureScreen({super.key, required this.imageBytes});

  @override
  State<PdfSignatureScreen> createState() => _PdfSignatureScreenState();
}

class _PdfSignatureScreenState extends State<PdfSignatureScreen> {
  Uint8List? _signatureBytes;
  
  // Sticker transform properties
  Offset _position = const Offset(100, 100);
  double _scale = 1.0;
  
  // State variables for gestures
  Offset? _startingFocalPoint;
  Offset? _previousPosition;
  double? _previousScale;

  bool _isSaving = false;
  bool _isProcessing = false;

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  void _openSignaturePad() {
    _signatureController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        _signatureController.clear();
                      },
                      child: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 16)),
                    ),
                    const Text('Draw Signature', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () async {
                        if (_signatureController.isNotEmpty) {
                          final bytes = await _signatureController.toPngBytes();
                          if (bytes != null) {
                            setState(() {
                              _signatureBytes = bytes;
                              // Reset position when a new signature is added
                              _position = const Offset(100, 100);
                              _scale = 1.0;
                            });
                          }
                        }
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Done', style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.grey[200],
                  child: Signature(
                    controller: _signatureController,
                    backgroundColor: Colors.grey[200]!,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processPickedImage(String path) async {
    setState(() => _isProcessing = true);
    
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Signature',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Signature',
          ),
        ],
      );

      if (croppedFile != null) {
        final bytes = await croppedFile.readAsBytes();
        final processedBytes = await _removeBackgroundBackend(bytes);
        
        if (mounted) {
          setState(() {
            _signatureBytes = processedBytes;
            _position = const Offset(100, 100);
            _scale = 1.0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error processing signature image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to process image.')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _importSignatureImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final hasPermission = await PermissionDisclosureUtils.requestWithDisclosure(
                  context,
                  permission: Permission.camera,
                  title: 'Camera Access Needed',
                  description: 'ToolHub requires camera access so you can take a picture of your physical signature to digitize it.',
                  icon: Icons.camera_alt,
                  color: Colors.blue,
                );
                if (!hasPermission) return;

                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  await _processPickedImage(image.path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                if (result != null && result.files.isNotEmpty) {
                  await _processPickedImage(result.files.first.path!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_signatureBytes == null) {
      Navigator.pop(context, null);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Decode background and signature
      final bgImage = img.decodeImage(widget.imageBytes);
      final sigImage = img.decodeImage(_signatureBytes!);

      if (bgImage != null && sigImage != null) {
        // Calculate the display ratio to map screen coordinates to image coordinates
        // We use LayoutBuilder context size to determine actual render size.
        // For simplicity, we calculate the aspect ratio and scale mapping here.
        final RenderBox renderBox = _bgImageKey.currentContext?.findRenderObject() as RenderBox;
        final displaySize = renderBox.size;
        
        final double scaleX = bgImage.width / displaySize.width;
        final double scaleY = bgImage.height / displaySize.height;
        
        // Since the image uses BoxFit.contain, the actual display size might have letterboxing.
        // We calculate the actual rendered rect of the image inside the displayBox.
        final double imgAspectRatio = bgImage.width / bgImage.height;
        final double viewAspectRatio = displaySize.width / displaySize.height;
        
        double drawWidth = displaySize.width;
        double drawHeight = displaySize.height;
        double drawOffsetX = 0;
        double drawOffsetY = 0;
        
        if (imgAspectRatio > viewAspectRatio) {
          // Image is wider than view (letterbox top/bottom)
          drawHeight = displaySize.width / imgAspectRatio;
          drawOffsetY = (displaySize.height - drawHeight) / 2;
        } else {
          // Image is taller than view (pillarbox left/right)
          drawWidth = displaySize.height * imgAspectRatio;
          drawOffsetX = (displaySize.width - drawWidth) / 2;
        }

        // True scale between the screen rendered image and the real bitmap
        final double trueScale = bgImage.width / drawWidth;

        // Map the drag position to the real bitmap coordinates
        final int targetX = ((_position.dx - drawOffsetX) * trueScale).toInt();
        final int targetY = ((_position.dy - drawOffsetY) * trueScale).toInt();
        
        // Map the scaled signature size to real bitmap size
        // The signature originally renders at 1:1 on screen, modified by _scale
        final int targetWidth = (sigImage.width * _scale * trueScale).toInt();
        final int targetHeight = (sigImage.height * _scale * trueScale).toInt();
        
        // Resize signature
        final resizedSig = img.copyResize(sigImage, width: targetWidth, height: targetHeight);

        // Composite them together
        img.compositeImage(
          bgImage, 
          resizedSig, 
          dstX: targetX, 
          dstY: targetY
        );

        final resultBytes = Uint8List.fromList(img.encodeJpg(bgImage, quality: 90));
        
        if (mounted) {
          Navigator.pop(context, resultBytes);
        }
      } else {
        throw Exception('Failed to decode images');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving signature: $e')));
      }
    }
  }

  final GlobalKey _bgImageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Signature', style: TextStyle(color: Colors.white)),
        actions: [
          if (!_isSaving)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green, size: 30),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: _isSaving || _isProcessing
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Expanded(
                  child: ClipRect(
                    child: Stack(
                      children: [
                        // Background Document Page
                        Center(
                          child: Image.memory(
                            widget.imageBytes,
                            key: _bgImageKey,
                            fit: BoxFit.contain,
                          ),
                        ),
                        // Draggable Signature Sticker
                        if (_signatureBytes != null)
                          Positioned(
                            left: _position.dx,
                            top: _position.dy,
                            child: GestureDetector(
                              onScaleStart: (details) {
                                _startingFocalPoint = details.focalPoint;
                                _previousPosition = _position;
                                _previousScale = _scale;
                              },
                              onScaleUpdate: (details) {
                                if (_previousPosition != null && _previousScale != null && _startingFocalPoint != null) {
                                  setState(() {
                                    // Handle panning
                                    final Offset delta = details.focalPoint - _startingFocalPoint!;
                                    _position = _previousPosition! + delta;
                                    
                                    // Handle scaling
                                    _scale = _previousScale! * details.scale;
                                  });
                                }
                              },
                              onScaleEnd: (details) {
                                _previousPosition = null;
                                _previousScale = null;
                                _startingFocalPoint = null;
                              },
                              child: Transform.scale(
                                scale: _scale,
                                alignment: Alignment.topLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.blue.withOpacity(0.5), width: 1 / _scale, style: BorderStyle.solid),
                                  ),
                                  child: Image.memory(
                                    _signatureBytes!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Container(
                  color: const Color(0xFF1F2937),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openSignaturePad,
                        icon: const Icon(Icons.draw),
                        label: Text(_signatureBytes == null ? 'Draw' : 'Redraw'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _importSignatureImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Import'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<Uint8List> _removeBackgroundBackend(Uint8List imageBytes) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/file-tools/remove-background');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'signature.png'));
      
      final response = await request.send();
      if (response.statusCode == 200) {
        return await response.stream.toBytes();
      } else {
        debugPrint('Backend background removal failed: ${response.statusCode}');
        // Fallback to local
        return await compute(_removeBackgroundWorker, imageBytes);
      }
    } catch (e) {
      debugPrint('Backend background removal error: $e');
      // Fallback to local
      return await compute(_removeBackgroundWorker, imageBytes);
    }
  }
}

// Background worker function to remove background from imported signatures
Uint8List _removeBackgroundWorker(Uint8List imageBytes) {
  final img.Image? original = img.decodeImage(imageBytes);
  if (original == null) return imageBytes;
  
  img.Image workingImg = original;
  // Scale down if too large to save memory and processing time
  if (workingImg.width > 1200) {
    workingImg = img.copyResize(workingImg, width: 1200);
  }

  // Calculate average brightness to determine the paper color dynamically
  double totalBrightness = 0;
  for (final pixel in workingImg) {
    totalBrightness += (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b);
  }
  double averageBrightness = totalBrightness / (workingImg.width * workingImg.height);

  // Soft thresholding parameters
  // Paper is usually close to the average brightness (since it occupies most of the image).
  // Ink is much darker.
  double highThreshold = averageBrightness * 0.9;
  double lowThreshold = averageBrightness * 0.6;

  // Create a new image with 4 channels (RGBA)
  final img.Image transparentImg = img.Image(width: workingImg.width, height: workingImg.height, numChannels: 4);

  for (int y = 0; y < workingImg.height; y++) {
    for (int x = 0; x < workingImg.width; x++) {
      final pixel = workingImg.getPixel(x, y);
      final num r = pixel.r;
      final num g = pixel.g;
      final num b = pixel.b;
      
      final double brightness = (0.299 * r + 0.587 * g + 0.114 * b);
      
      if (brightness >= highThreshold) {
        // It's paper background
        transparentImg.setPixelRgba(x, y, 255, 255, 255, 0); 
      } else if (brightness <= lowThreshold) {
        // It's definitely ink. Make it dark/black and fully opaque.
        // We use a dark color like deep blue/black for signatures.
        transparentImg.setPixelRgba(x, y, 20, 20, 40, 255); 
      } else {
        // Anti-aliasing / soft edge between ink and paper.
        double ratio = (highThreshold - brightness) / (highThreshold - lowThreshold);
        int alpha = (ratio * 255).toInt().clamp(0, 255);
        transparentImg.setPixelRgba(x, y, 20, 20, 40, alpha); 
      }
    }
  }

  return Uint8List.fromList(img.encodePng(transparentImg));
}
