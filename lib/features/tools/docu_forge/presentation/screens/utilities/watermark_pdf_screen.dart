import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/pdf_utils_service.dart';
import '../../../data/docuforge_database_service.dart';
import '../../../data/models/document_model.dart';

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
        final newDoc = Document()
          ..name = 'Watermarked_${DateTime.now().millisecondsSinceEpoch}.pdf'
          ..pdfPath = outputFile.path
          ..thumbnailPath = ''
          ..fileSize = outputFile.lengthSync()
          ..pageCount = 1
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..folderId = '';

        await DocuForgeDatabaseService.instance.saveDocument(newDoc);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully added watermark!')));
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
    const color = Color(0xFF06B6D4);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: color,
        title: const Text('Add Watermark', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
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
                  child: const Text('Apply Watermark', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
}
