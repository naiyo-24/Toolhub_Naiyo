import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/document_model.dart';
import '../../data/docuforge_database_service.dart';
import '../../data/pdf_utils_service.dart';
import 'utilities/pdf_eraser_screen.dart';
import 'utilities/pdf_signature_screen.dart';

class PdfEditorScreen extends StatefulWidget {
  final Document document;

  const PdfEditorScreen({super.key, required this.document});

  @override
  State<PdfEditorScreen> createState() => _PdfEditorScreenState();
}

class _PdfPageInfo {
  final int originalIndex;
  Uint8List thumbnail;
  Uint8List? editedHighResImage;
  int rotationAngle; // 0, 90, 180, 270
  bool isDeleted;

  _PdfPageInfo({
    required this.originalIndex,
    required this.thumbnail,
    this.rotationAngle = 0,
    this.isDeleted = false,
  });
}

class _PdfEditorScreenState extends State<PdfEditorScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<_PdfPageInfo> _pages = [];

  @override
  void initState() {
    super.initState();
    _loadThumbnails();
  }

  Future<void> _loadThumbnails() async {
    try {
      final file = File(widget.document.pdfPath);
      final bytes = await file.readAsBytes();
      
      final List<_PdfPageInfo> pages = [];
      int index = 0;
      
      await for (final page in Printing.raster(bytes, dpi: 72)) {
        final pngBytes = await page.toPng();
        pages.add(_PdfPageInfo(
          originalIndex: index,
          thumbnail: pngBytes,
        ));
        index++;
      }
      
      if (mounted) {
        setState(() {
          _pages = pages;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error rasterizing PDF: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load PDF pages for editing')));
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    
    try {
      // Create instructions list based on current UI state
      // We want a list of maps containing original index and rotation
      final List<Map<String, dynamic>> layoutInstructions = [];
      for (var page in _pages) {
        if (!page.isDeleted) {
          layoutInstructions.add({
            'originalIndex': page.originalIndex,
            'rotation': page.rotationAngle,
            'editedImage': page.editedHighResImage,
          });
        }
      }

      final originalFile = File(widget.document.pdfPath);
      final newFile = await PdfUtilsService.rebuildPdf(originalFile, layoutInstructions);
      
      if (newFile != null) {
        // Update document path and page count
        widget.document.pdfPath = newFile.path;
        widget.document.pageCount = layoutInstructions.length;
        widget.document.updatedAt = DateTime.now();
        
        try {
          await DocuForgeDatabaseService.instance.saveDocument(widget.document);
        } catch (dbError) {
          debugPrint('Database save error: $dbError');
          // If we fail to save to DB (e.g. temporary external document), we still built the PDF successfully!
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved successfully!')));
          Navigator.pop(context, true); // true indicates changes were made
        }
      } else {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save changes')));
        }
      }
    } catch (e) {
      debugPrint('Save Error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  void _rotatePage(int index) {
    setState(() {
      _pages[index].rotationAngle = (_pages[index].rotationAngle + 90) % 360;
    });
  }

  void _deletePage(int index) {
    setState(() {
      _pages[index].isDeleted = true;
      _pages.removeAt(index);
    });
  }

  Future<Uint8List> _getPageImage(_PdfPageInfo pageInfo) async {
    if (pageInfo.editedHighResImage != null) {
      return pageInfo.editedHighResImage!;
    }
    
    // To completely prevent OutOfMemoryError crashes on massive PDFs, 
    // we reuse the safely extracted thumbnail instead of trying to 
    // extract a massive new high-res image into RAM.
    return pageInfo.thumbnail;
  }

  Future<void> _openAdvancedEditor(int index) async {
    final pageInfo = _pages[index];
    setState(() => _isLoading = true);

    try {
      final highResBytes = await _getPageImage(pageInfo);

      if (mounted) {
        setState(() => _isLoading = false);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProImageEditor.memory(
              highResBytes!,
              callbacks: ProImageEditorCallbacks(
                onImageEditingComplete: (Uint8List editedBytes) async {
                  setState(() {
                    pageInfo.editedHighResImage = editedBytes;
                    pageInfo.thumbnail = editedBytes; // Update thumbnail as well so UI reflects changes
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Editor Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load advanced editor.')));
      }
    }
  }

  Future<void> _openEraserTool(int index) async {
    final pageInfo = _pages[index];
    setState(() => _isLoading = true);

    try {
      final highResBytes = await _getPageImage(pageInfo);

      if (mounted) {
        setState(() => _isLoading = false);
        final editedBytes = await Navigator.push<Uint8List?>(
          context,
          MaterialPageRoute(
            builder: (context) => PdfEraserScreen(imageBytes: highResBytes!),
          ),
        );

        if (editedBytes != null) {
          setState(() {
            pageInfo.editedHighResImage = editedBytes;
            pageInfo.thumbnail = editedBytes;
          });
          
          // Automatically save the PDF so the user doesn't have to press the SAVE button manually
          await _saveChanges();
        }
      }
    } catch (e) {
      debugPrint('Eraser Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load eraser tool.')));
      }
    }
  }

  Future<void> _openSignatureTool(int index) async {
    final pageInfo = _pages[index];
    setState(() => _isLoading = true);

    try {
      final highResBytes = await _getPageImage(pageInfo);

      if (mounted) {
        setState(() => _isLoading = false);
        final editedBytes = await Navigator.push<Uint8List?>(
          context,
          MaterialPageRoute(
            builder: (context) => PdfSignatureScreen(imageBytes: highResBytes!),
          ),
        );

        if (editedBytes != null) {
          setState(() {
            pageInfo.editedHighResImage = editedBytes;
            pageInfo.thumbnail = editedBytes;
          });
          
          await _saveChanges();
        }
      }
    } catch (e) {
      debugPrint('Signature Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load signature tool.')));
      }
    }
  }

  Future<void> _openCropTool(int index) async {
    final pageInfo = _pages[index];
    setState(() => _isLoading = true);

    try {
      final highResBytes = await _getPageImage(pageInfo);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_crop_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(highResBytes);

      if (mounted) {
        setState(() => _isLoading = false);
        
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: tempFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Page',
              toolbarColor: Colors.blue,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Crop Page',
            ),
          ],
        );

        if (croppedFile != null) {
          final croppedBytes = await croppedFile.readAsBytes();
          setState(() {
            pageInfo.editedHighResImage = croppedBytes;
            pageInfo.thumbnail = croppedBytes;
          });
          
          await _saveChanges();
        }
      }
    } catch (e) {
      debugPrint('Crop Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load crop tool.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        title: const Text('Edit Pages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
        : Padding(
            padding: const EdgeInsets.all(12.0),
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false, // We will just use standard list tiles for simplicity instead of grid
              itemCount: _pages.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _pages.removeAt(oldIndex);
                  _pages.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final pageInfo = _pages[index];
                return ReorderableDragStartListener(
                  key: ValueKey(pageInfo.originalIndex),
                  index: index,
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(width: 16),
                          Container(
                            height: 120,
                            width: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Transform.rotate(
                              angle: pageInfo.rotationAngle * 3.14159 / 180,
                              child: Image.memory(pageInfo.thumbnail, fit: BoxFit.contain),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              reverse: true,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.cleaning_services, color: Colors.purple),
                                    tooltip: 'Whiteout Eraser',
                                    onPressed: () => _openEraserTool(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.draw, color: Colors.orange),
                                    tooltip: 'Add Signature',
                                    onPressed: () => _openSignatureTool(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.crop, color: Colors.teal),
                                    tooltip: 'Crop Page',
                                    onPressed: () => _openCropTool(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.green),
                                    tooltip: 'Advanced Edit',
                                    onPressed: () => _openAdvancedEditor(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.rotate_right, color: Colors.blue),
                                    onPressed: () => _rotatePage(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deletePage(index),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Icon(Icons.drag_handle, color: Colors.grey),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }
}
