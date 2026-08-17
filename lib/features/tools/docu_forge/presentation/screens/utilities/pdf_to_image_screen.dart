import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

class PdfToImageScreen extends StatefulWidget {
  const PdfToImageScreen({super.key});

  @override
  State<PdfToImageScreen> createState() => _PdfToImageScreenState();
}

class _PdfPageSelection {
  final int index;
  final Uint8List imageBytes;
  bool isSelected;

  _PdfPageSelection({
    required this.index,
    required this.imageBytes,
    this.isSelected = false,
  });
}

class _PdfToImageScreenState extends State<PdfToImageScreen> {
  File? _selectedFile;
  bool _isLoading = false;
  bool _isProcessing = false;
  List<_PdfPageSelection> _pages = [];

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      setState(() {
        _selectedFile = file;
        _isLoading = true;
        _pages = [];
      });
      _loadThumbnails(file);
    }
  }

  Future<void> _loadThumbnails(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final List<_PdfPageSelection> pages = [];
      int index = 0;
      
      // Rasterize at 72 DPI to avoid OutOfMemoryError on large/high-res PDFs
      await for (final page in Printing.raster(bytes, dpi: 72)) {
        final pngBytes = await page.toPng();
        pages.add(_PdfPageSelection(
          index: index,
          imageBytes: pngBytes,
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
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load PDF pages')));
      }
    }
  }

  Future<File?> _processSelectedImages() async {
    final selectedPages = _pages.where((p) => p.isSelected).toList();
    if (selectedPages.isEmpty) return null;

    final tempDir = await getTemporaryDirectory();

    if (selectedPages.length == 1) {
      // Return a single image
      final file = File('${tempDir.path}/page_${selectedPages.first.index + 1}.png');
      await file.writeAsBytes(selectedPages.first.imageBytes);
      return file;
    } else {
      // Zip them up
      final archive = Archive();
      for (final p in selectedPages) {
        final archiveFile = ArchiveFile('page_${p.index + 1}.png', p.imageBytes.length, p.imageBytes);
        archive.addFile(archiveFile);
      }

      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) return null;

      final zipFile = File('${tempDir.path}/extracted_images_${DateTime.now().millisecondsSinceEpoch}.zip');
      await zipFile.writeAsBytes(zipData);
      return zipFile;
    }
  }

  Future<void> _shareImages() async {
    final selectedCount = _pages.where((p) => p.isSelected).length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 page to share')));
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final file = await _processSelectedImages();
      if (file != null && mounted) {
        // ignore: deprecated_member_use
        Share.shareXFiles([XFile(file.path)], text: 'Here are the extracted images!');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveImagesLocal() async {
    final selectedCount = _pages.where((p) => p.isSelected).length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 page to save')));
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final file = await _processSelectedImages();
      if (file != null) {
        final bytes = await file.readAsBytes();
        final ext = selectedCount == 1 ? 'png' : 'zip';
        
        final String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Extracted Images',
          fileName: 'extracted_${DateTime.now().millisecondsSinceEpoch}.$ext',
          type: FileType.custom,
          allowedExtensions: [ext],
          bytes: bytes,
        );

        if (outputPath != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully!')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF4ADE80);
    final selectedCount = _pages.where((p) => p.isSelected).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: color,
        title: const Text('PDF to Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_pages.isNotEmpty)
            TextButton(
              onPressed: () {
                final allSelected = selectedCount == _pages.length;
                setState(() {
                  for (var p in _pages) {
                    p.isSelected = !allSelected;
                  }
                });
              },
              child: Text(selectedCount == _pages.length ? 'Deselect All' : 'Select All', style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_selectedFile == null && !_isLoading)
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: _selectFile,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: color, width: 2),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image_rounded, size: 64, color: color),
                            SizedBox(height: 16),
                            Text('Tap to select a PDF to convert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else if (_isLoading)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: color),
                        SizedBox(height: 16),
                        Text('Reading PDF pages...'),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        final page = _pages[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              page.isSelected = !page.isSelected;
                            });
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: page.isSelected ? color : Colors.grey.shade300,
                                    width: page.isSelected ? 4 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(page.imageBytes, fit: BoxFit.cover),
                                ),
                              ),
                              if (page.isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 20),
                                  ),
                                ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (context) => Scaffold(
                                        backgroundColor: Colors.black,
                                        appBar: AppBar(
                                          backgroundColor: Colors.black,
                                          iconTheme: const IconThemeData(color: Colors.white),
                                          title: Text('Page ${page.index + 1}', style: const TextStyle(color: Colors.white)),
                                        ),
                                        body: Center(
                                          child: InteractiveViewer(
                                            child: Image.memory(page.imageBytes),
                                          ),
                                        ),
                                      ),
                                    ));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                                  ),
                                  child: Text(
                                    'Page ${page.index + 1}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (_pages.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_isProcessing || selectedCount == 0) ? null : _shareImages,
                            icon: const Icon(Icons.share_rounded),
                            label: Text(selectedCount == 1 ? 'Share 1 Image' : 'Share Zip ($selectedCount)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: color,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: color, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_isProcessing || selectedCount == 0) ? null : _saveImagesLocal,
                            icon: const Icon(Icons.download_rounded),
                            label: Text(selectedCount == 1 ? 'Save 1 Image' : 'Save Zip ($selectedCount)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Processing Images...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
