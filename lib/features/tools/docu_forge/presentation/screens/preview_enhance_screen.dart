import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import '../../data/local_storage_service.dart';
import '../../data/models/document_model.dart';
import '../../data/docuforge_database_service.dart';
import '../../data/ocr_service.dart';
import 'package:image_cropper/image_cropper.dart';
import 'utilities/pdf_eraser_screen.dart';
import 'utilities/pdf_signature_screen.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/docuforge_providers.dart';

class PreviewEnhanceScreen extends ConsumerStatefulWidget {
  final List<File> images;

  const PreviewEnhanceScreen({super.key, required this.images});

  @override
  ConsumerState<PreviewEnhanceScreen> createState() => _PreviewEnhanceScreenState();
}

class _PreviewEnhanceScreenState extends ConsumerState<PreviewEnhanceScreen> {
  int _currentIndex = 0;
  bool _isGeneratingPdf = false;
  bool _isProcessingImage = false;
  
  // Keep track of modified images
  late List<File> _baseImages; // Geometry changes (crop, rotate)
  late List<File> _currentImages; // Color changes (filters)

  @override
  void initState() {
    super.initState();
    _baseImages = List.from(widget.images);
    _currentImages = List.from(widget.images);
  }

  Future<void> _applyFilter(String filterType) async {
    if (filterType == 'original') {
      setState(() {
        _currentImages[_currentIndex] = _baseImages[_currentIndex];
      });
      return;
    }

    setState(() {
      _isProcessingImage = true;
    });

    try {
      final file = _baseImages[_currentIndex];
      final bytes = await file.readAsBytes();
      
      // Run heavy image processing in an isolate
      final processedBytes = await compute(_processImage, {'bytes': bytes, 'type': filterType});
      
      final tempPath = await LocalStorageService.getCropTempPath();
      final newFile = File('$tempPath/filtered_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await newFile.writeAsBytes(processedBytes);

      setState(() {
        _currentImages[_currentIndex] = newFile;
        if (filterType == 'rotate_90') {
          _baseImages[_currentIndex] = newFile; // rotation alters base geometry
        }
      });
    } catch (e) {
      debugPrint('Error applying filter: $e');
    } finally {
      setState(() {
        _isProcessingImage = false;
      });
    }
  }

  Future<void> _cropImage() async {
    final file = _baseImages[_currentIndex];
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Document',
          toolbarColor: const Color(0xFF2563EB),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Document',
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _baseImages[_currentIndex] = File(croppedFile.path);
        _currentImages[_currentIndex] = File(croppedFile.path);
      });
    }
  }

  // Static method for compute isolate
  static List<int> _processImage(Map<String, dynamic> args) {
    final bytes = args['bytes'] as Uint8List;
    final type = args['type'] as String;
    
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    switch (type) {
      case 'bw':
        img.grayscale(image);
        img.adjustColor(image, contrast: 1.5);
        break;
      case 'contrast_bw':
        img.grayscale(image);
        img.adjustColor(image, contrast: 1.8, brightness: 1.1);
        break;
      case 'sharp_black':
        img.grayscale(image);
        img.adjustColor(image, contrast: 2.2, brightness: 1.2);
        break;
      case 'carbon':
        img.grayscale(image);
        img.adjustColor(image, contrast: 1.8, brightness: 0.9);
        break;
      case 'grayscale':
        img.grayscale(image);
        break;
      case 'document':
        img.adjustColor(image, contrast: 1.3, brightness: 1.1);
        break;
      case 'vivid':
        img.adjustColor(image, contrast: 1.2, saturation: 1.5, brightness: 1.1);
        break;
      case 'vibrant':
        img.adjustColor(image, contrast: 1.4, saturation: 1.8);
        break;
      case 'soft':
        img.adjustColor(image, contrast: 0.9, saturation: 0.8, brightness: 1.2);
        break;
      case 'color_pop':
        img.adjustColor(image, contrast: 1.3, saturation: 2.0, brightness: 1.1);
        break;
      case 'rotate_90':
        image = img.copyRotate(image, angle: 90);
        break;
    }

    return img.encodeJpg(image, quality: 90);
  }

  Future<void> _openEraserTool() async {
    setState(() => _isProcessingImage = true);
    
    try {
      final imageFile = _currentImages[_currentIndex];
      final bytes = await imageFile.readAsBytes();
      
      if (mounted) {
        setState(() => _isProcessingImage = false);
        
        final editedBytes = await Navigator.push<Uint8List?>(
          context,
          MaterialPageRoute(
            builder: (context) => PdfEraserScreen(imageBytes: bytes),
          ),
        );

        if (editedBytes != null && mounted) {
          setState(() => _isProcessingImage = true);
          // Save the edited bytes back to the temporary file
          await imageFile.writeAsBytes(editedBytes);
          setState(() => _isProcessingImage = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eraser Error: $e')));
      }
    }
  }

  Future<void> _openSignatureTool() async {
    setState(() => _isProcessingImage = true);
    
    try {
      final imageFile = _currentImages[_currentIndex];
      final bytes = await imageFile.readAsBytes();
      
      if (mounted) {
        setState(() => _isProcessingImage = false);
        
        final editedBytes = await Navigator.push<Uint8List?>(
          context,
          MaterialPageRoute(
            builder: (context) => PdfSignatureScreen(imageBytes: bytes),
          ),
        );

        if (editedBytes != null && mounted) {
          setState(() => _isProcessingImage = true);
          await imageFile.writeAsBytes(editedBytes);
          setState(() => _isProcessingImage = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signature Error: $e')));
      }
    }
  }

  Future<void> _openAdvancedEditor() async {
    setState(() => _isProcessingImage = true);
    
    try {
      final imageFile = _currentImages[_currentIndex];
      final bytes = await imageFile.readAsBytes();
      
      if (mounted) {
        setState(() => _isProcessingImage = false);
        
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProImageEditor.memory(
              bytes,
              callbacks: ProImageEditorCallbacks(
                onImageEditingComplete: (Uint8List editedBytes) async {
                  if (mounted) {
                    setState(() => _isProcessingImage = true);
                    await imageFile.writeAsBytes(editedBytes);
                    setState(() => _isProcessingImage = false);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Editor Error: $e')));
      }
    }
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final pdf = pw.Document();

      for (var imageFile in _currentImages) {
        final image = pw.MemoryImage(
          await imageFile.readAsBytes(),
        );

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(
              image.width?.toDouble() ?? PdfPageFormat.a4.width,
              image.height?.toDouble() ?? PdfPageFormat.a4.height,
              marginAll: 0,
            ),
            build: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Image(image, fit: pw.BoxFit.cover),
              );
            },
          ),
        );
      }

      final pdfStoragePath = await LocalStorageService.getPdfStoragePath();
      final docName = 'Scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfFile = File('$pdfStoragePath/$docName');
      await pdfFile.writeAsBytes(await pdf.save());

      // Save to Isar Database
      final newDoc = Document()
        ..name = docName
        ..pdfPath = pdfFile.path
        ..thumbnailPath = _currentImages.first.path // First image as thumbnail
        ..pageCount = _currentImages.length
        ..fileSize = await pdfFile.length()
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await DocuForgeDatabaseService.instance.saveDocument(newDoc);

      if (mounted) {
        ref.invalidate(recentDocumentsProvider);
        Navigator.pop(context); // Go back to Home
      }
    } catch (e) {
      debugPrint('Error generating PDF: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apply Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterOption('Original', 'original', Icons.image),
                    _buildFilterOption('Document', 'document', Icons.article),
                    _buildFilterOption('Vivid Light', 'vivid', Icons.light_mode),
                    _buildFilterOption('Contrast B&W', 'contrast_bw', Icons.contrast),
                    _buildFilterOption('Vibrant', 'vibrant', Icons.color_lens),
                    _buildFilterOption('Soft Tone', 'soft', Icons.blur_on),
                    _buildFilterOption('Sharp Black', 'sharp_black', Icons.edit),
                    _buildFilterOption('B&W', 'bw', Icons.filter_b_and_w),
                    _buildFilterOption('Carbon', 'carbon', Icons.dark_mode),
                    _buildFilterOption('Gray', 'grayscale', Icons.tonality),
                    _buildFilterOption('Color Pop', 'color_pop', Icons.star),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, String type, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _applyFilter(type);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isGeneratingPdf) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating PDF...', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        title: Text('Preview (${_currentIndex + 1}/${_currentImages.length})',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: _currentImages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Image.file(_currentImages[index], fit: BoxFit.contain),
                    );
                  },
                ),
                if (_isProcessingImage)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          // Tool bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 16),
                  _buildToolButton(Icons.crop, 'Crop', onTap: _cropImage),
                  const SizedBox(width: 16),
                  _buildToolButton(Icons.cleaning_services, 'Eraser', color: Colors.purple, onTap: _openEraserTool),
                  const SizedBox(width: 16),
                  _buildToolButton(Icons.draw, 'Signature', color: Colors.orange, onTap: _openSignatureTool),
                  const SizedBox(width: 16),
                  _buildToolButton(Icons.edit, 'Advanced Edit', color: Colors.green, onTap: _openAdvancedEditor),
                  const SizedBox(width: 16),
                  _buildToolButton(Icons.filter_b_and_w, 'Filter', onTap: _showFilterOptions),
                  const SizedBox(width: 16),
                  _buildToolButton(Icons.text_fields, 'Extract Text', onTap: () async {
                    setState(() => _isProcessingImage = true);
                    final text = await OcrService.extractTextFromImage(_currentImages[_currentIndex]);
                    setState(() => _isProcessingImage = false);
                    
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Extracted Text'),
                          content: SingleChildScrollView(child: Text(text.isNotEmpty ? text : 'No text found.')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
                          ],
                        )
                      );
                    }
                  }),
                  const SizedBox(width: 16),
                  _buildToolButton(Icons.rotate_right, 'Rotate', onTap: () => _applyFilter('rotate_90')),
                  const SizedBox(width: 16),
                  _buildToolButton(
                    Icons.delete_outline,
                    'Delete',
                    color: Colors.red,
                    onTap: () {
                      if (_currentImages.length > 1) {
                        setState(() {
                          _currentImages.removeAt(_currentIndex);
                          if (_currentIndex >= _currentImages.length) {
                            _currentIndex--;
                          }
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label, {Color color = const Color(0xFF111827), required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
