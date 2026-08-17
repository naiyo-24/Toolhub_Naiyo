import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/pdf_utils_service.dart';
import '../../../data/docuforge_database_service.dart';
import '../../../data/models/document_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import '../pdf_viewer_screen.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';

class WatermarkPdfScreen extends StatefulWidget {
  const WatermarkPdfScreen({super.key});

  @override
  State<WatermarkPdfScreen> createState() => _WatermarkPdfScreenState();
}

class _WatermarkPdfScreenState extends State<WatermarkPdfScreen> {
  File? _selectedFile;
  final TextEditingController _watermarkController = TextEditingController();
  bool _isProcessing = false;
  
  bool _isImageMode = false;
  File? _watermarkImageFile;
  File? _previewFile;
  Document? _generatedDoc;

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = File(result.files.first.path!);
      });
    }
  }

  Future<void> _selectWatermarkImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _watermarkImageFile = File(result.files.first.path!);
      });
    }
  }

  Future<void> _processFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PDF file first')));
      return;
    }
    
    if (!_isImageMode && _watermarkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter watermark text')));
      return;
    }
    if (_isImageMode && _watermarkImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a watermark image')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final outputFile = _isImageMode 
          ? await PdfUtilsService.watermarkPdfImage(_selectedFile!, _watermarkImageFile!)
          : await PdfUtilsService.watermarkPdfText(_selectedFile!, _watermarkController.text);
          
      if (outputFile != null) {
        if (mounted) {
          setState(() {
            _previewFile = outputFile;
          });
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveFile() async {
    if (_previewFile == null) return;
    try {
      final newDoc = Document()
        ..name = 'Watermarked_${DateTime.now().millisecondsSinceEpoch}.pdf'
        ..pdfPath = _previewFile!.path
        ..thumbnailPath = ''
        ..fileSize = _previewFile!.lengthSync()
        ..pageCount = 1
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..folderId = '';

      await DocuForgeDatabaseService.instance.saveDocument(newDoc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully saved watermarked PDF!')));
        setState(() {
          _generatedDoc = newDoc;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF06B6D4);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: color,
        title: const Text('Add Watermark', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _generatedDoc != null
        ? _buildSuccessView()
        : _previewFile != null
          ? Column(
              children: [
                Expanded(
                  child: SfPdfViewer.file(_previewFile!),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _previewFile = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: color),
                            foregroundColor: color,
                          ),
                          child: const Text('Cancel / Retry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Save PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: _selectFile,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: color, width: 2),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.picture_as_pdf, size: 48, color: _selectedFile == null ? Colors.grey : color),
                              const SizedBox(height: 16),
                              Text(
                                _selectedFile == null ? 'Tap to select PDF' : _selectedFile!.path.split('/').last,
                                style: TextStyle(fontWeight: FontWeight.bold, color: _selectedFile == null ? Colors.grey : Colors.black),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Text'),
                          Switch(
                            value: _isImageMode,
                            onChanged: (val) {
                              setState(() {
                                _isImageMode = val;
                              });
                            },
                            activeColor: color,
                          ),
                          const Text('Image'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!_isImageMode)
                        TextField(
                          controller: _watermarkController,
                          decoration: const InputDecoration(
                            labelText: 'Watermark Text',
                            hintText: 'e.g. CONFIDENTIAL',
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: color, width: 2)),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _selectWatermarkImage,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, color: _watermarkImageFile == null ? Colors.grey : color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _watermarkImageFile == null ? 'Select Watermark Image' : _watermarkImageFile!.path.split('/').last,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: _watermarkImageFile == null ? Colors.grey : Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isProcessing ? null : _processFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Preview Watermark', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSuccessView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          NeoCard(
            backgroundColor: const Color(0xFF4ADE80),
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.check_circle_rounded, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'PDF Watermarked Successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _generatedDoc!.name,
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewerScreen(document: _generatedDoc!)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
            icon: const Icon(Icons.preview_rounded),
            label: const Text('Preview PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // ignore: deprecated_member_use
              Share.shareXFiles([XFile(_generatedDoc!.pdfPath)], text: 'My Watermarked PDF');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final file = File(_generatedDoc!.pdfPath);
                final bytes = await file.readAsBytes();
                final String? outputPath = await FilePicker.platform.saveFile(
                  dialogTitle: 'Save PDF',
                  fileName: _generatedDoc!.name,
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                  bytes: bytes,
                );
                if (outputPath != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully!')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Save Local', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Back to Tools', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
          )
        ],
      ),
    );
  }
}
