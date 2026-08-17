import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/pdf_utils_service.dart';
import '../../../data/docuforge_database_service.dart';
import '../../../data/models/document_model.dart';
import 'package:share_plus/share_plus.dart';
import '../pdf_viewer_screen.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';

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
          setState(() {
            _generatedDoc = newDoc;
          });
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
      body: _generatedDoc != null
        ? _buildSuccessView()
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
                Text(
                  widget.isUnlockMode ? 'PDF Unlocked Successfully!' : 'PDF Protected Successfully!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
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
              Share.shareXFiles([XFile(_generatedDoc!.pdfPath)], text: widget.isUnlockMode ? 'My Unlocked PDF' : 'My Protected PDF');
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
