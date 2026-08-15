import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/pdf_utils_service.dart';
import '../../../data/docuforge_database_service.dart';
import '../../../data/models/document_model.dart';

class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _PdfPageSelection {
  final int index;
  final Uint8List thumbnail;
  bool isSelected;

  _PdfPageSelection({
    required this.index,
    required this.thumbnail,
    this.isSelected = false,
  });
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
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
      
      await for (final page in Printing.raster(bytes, dpi: 72)) {
        final pngBytes = await page.toPng();
        pages.add(_PdfPageSelection(
          index: index,
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
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load PDF pages')));
      }
    }
  }

  Future<void> _splitPdf() async {
    final selectedIndices = _pages.where((p) => p.isSelected).map((p) => p.index).toList();
    if (selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 page to extract')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Re-use rebuildPdf for splitting by just passing the selected indices with 0 rotation
      final List<Map<String, dynamic>> instructions = selectedIndices.map((idx) => {
        'originalIndex': idx,
        'rotation': 0,
      }).toList();

      final outputFile = await PdfUtilsService.rebuildPdf(_selectedFile!, instructions);
      
      if (outputFile != null) {
        final newDoc = Document()
          ..name = 'Extracted_${DateTime.now().millisecondsSinceEpoch}.pdf'
          ..pdfPath = outputFile.path
          ..thumbnailPath = ''
          ..fileSize = outputFile.lengthSync()
          ..pageCount = instructions.length
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..folderId = '';

        await DocuForgeDatabaseService.instance.saveDocument(newDoc);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully extracted pages!')));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFEAB308);
    final selectedCount = _pages.where((p) => p.isSelected).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: color,
        title: const Text('Split / Extract PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                            Icon(Icons.picture_as_pdf, size: 64, color: color),
                            SizedBox(height: 16),
                            Text('Tap to select a PDF to split', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                        crossAxisCount: 3,
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
                          child: Card(
                            elevation: page.isSelected ? 8 : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: page.isSelected ? color : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      page.thumbnail,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                if (page.isSelected)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                                    ),
                                  ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${page.index + 1}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), offset: const Offset(0, -2), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      Text('$selectedCount pages selected', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: selectedCount > 0 && !_isProcessing ? _splitPdf : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Extract Pages', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
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
                    Text('Extracting pages...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
