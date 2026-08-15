import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/pdf_utils_service.dart';
import '../../../data/docuforge_database_service.dart';
import '../../../data/models/document_model.dart';

class PdfSecurityScreen extends StatefulWidget {
  final bool isUnlockMode;
  const PdfSecurityScreen({super.key, required this.isUnlockMode});

  @override
  State<PdfSecurityScreen> createState() => _PdfSecurityScreenState();
}

class _PdfSecurityScreenState extends State<PdfSecurityScreen> {
  File? _selectedFile;
  final TextEditingController _passwordController = TextEditingController();
  bool _isProcessing = false;
  bool _obscureText = true;

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

  Future<void> _processFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PDF file first')));
      return;
    }
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a password')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      File? outputFile;
      final password = _passwordController.text;

      if (widget.isUnlockMode) {
        outputFile = await PdfUtilsService.removePassword(_selectedFile!, password);
        if (outputFile == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to unlock. Incorrect password?')));
          setState(() => _isProcessing = false);
          return;
        }
      } else {
        outputFile = await PdfUtilsService.protectPdf(_selectedFile!, password, password);
      }

      if (outputFile != null) {
        final newDoc = Document()
          ..name = '${widget.isUnlockMode ? "Unlocked" : "Locked"}_${DateTime.now().millisecondsSinceEpoch}.pdf'
          ..pdfPath = outputFile.path
          ..thumbnailPath = ''
          ..fileSize = outputFile.lengthSync()
          ..pageCount = 1
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..folderId = '';

        await DocuForgeDatabaseService.instance.saveDocument(newDoc);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully ${widget.isUnlockMode ? 'unlocked' : 'locked'} PDF!')));
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
    final color = widget.isUnlockMode ? const Color(0xFF14B8A6) : const Color(0xFFEF4444);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: color,
        title: Text(widget.isUnlockMode ? 'Unlock PDF' : 'Protect PDF', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                TextField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: widget.isUnlockMode ? 'Enter Current Password' : 'Enter New Password',
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: color, width: 2)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off, color: color),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
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
                  child: Text(
                    widget.isUnlockMode ? 'Unlock PDF' : 'Apply Password',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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
