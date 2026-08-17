import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/features/tools/docu_forge/data/docuforge_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:tool_hub/features/tools/docu_forge/presentation/screens/pdf_viewer_screen.dart';
import 'package:tool_hub/features/tools/docu_forge/data/models/document_model.dart';

class PdfConverterScreen extends ConsumerStatefulWidget {
  final String title;
  final String endpoint;
  final List<String> allowedExtensions;
  final String outputExtension;

  const PdfConverterScreen({
    super.key,
    required this.title,
    required this.endpoint,
    required this.allowedExtensions,
    required this.outputExtension,
  });

  @override
  ConsumerState<PdfConverterScreen> createState() => _PdfConverterScreenState();
}

class _PdfConverterScreenState extends ConsumerState<PdfConverterScreen> {
  final DocuForgeService _service = DocuForgeService();
  File? _selectedFile;
  bool _isProcessing = false;
  String? _convertedFilePath;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.allowedExtensions,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = File(result.files.first.path!);
        _convertedFilePath = null;
      });
    }
  }

  Future<void> _convertFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final bytes = await _service.convertFile(_selectedFile!, widget.endpoint);

      final tempDir = await getTemporaryDirectory();
      final outPath = '${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.${widget.outputExtension}';
      final file = File(outPath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        setState(() {
          _convertedFilePath = outPath;
        });
        SnackbarUtils.showNeoSnackBar(context, message: 'Conversion successful!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.title, style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NeoCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.sync_alt_rounded, size: 64, color: AppColors.primaryGreen),
                  const SizedBox(height: 16),
                  Text(
                    'Select a .${widget.allowedExtensions.join(', .')} file to convert to .${widget.outputExtension}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyText,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _pickFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: Text(_selectedFile == null ? 'Select File' : 'Change File'),
                  ),
                ],
              ),
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 24),
              NeoCard(
                backgroundColor: AppColors.primaryYellow,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedFile!.path.split('/').last,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isProcessing ? null : _convertFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.black, width: 3),
                  ),
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                          SizedBox(width: 12),
                          Text('Converting...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      )
                    : const Text(
                        'CONVERT NOW',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
              ),
            ],
            if (_convertedFilePath != null) ...[
              const SizedBox(height: 32),
              NeoCard(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Conversion Completed!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  if (widget.outputExtension.toLowerCase() == 'pdf') {
                     final doc = Document()
                       ..name = _convertedFilePath!.split('/').last
                       ..pdfPath = _convertedFilePath!
                       ..fileSize = File(_convertedFilePath!).lengthSync()
                       ..createdAt = DateTime.now()
                       ..updatedAt = DateTime.now()
                       ..pageCount = 1
                       ..thumbnailPath = ''
                       ..folderId = '';
                     Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewerScreen(document: doc)));
                  } else {
                     OpenFilex.open(_convertedFilePath!);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                icon: const Icon(Icons.preview_rounded),
                label: const Text('Preview File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // ignore: deprecated_member_use
                  Share.shareXFiles([XFile(_convertedFilePath!)], text: 'My Converted File');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final bytes = await File(_convertedFilePath!).readAsBytes();
                    final String? outputPath = await FilePicker.platform.saveFile(
                      dialogTitle: 'Save Converted File',
                      fileName: _convertedFilePath!.split('/').last,
                      type: FileType.custom,
                      allowedExtensions: [widget.outputExtension],
                      bytes: bytes,
                    );
                    if (outputPath != null && mounted) {
                      SnackbarUtils.showNeoSnackBar(context, message: 'Saved successfully!');
                    }
                  } catch (e) {
                    if (mounted) {
                      SnackbarUtils.showNeoSnackBar(context, message: 'Error saving: $e');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Save Local', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
