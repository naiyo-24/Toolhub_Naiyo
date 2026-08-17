import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../data/models/document_model.dart';
import '../../data/google_drive_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tool_hub/core/utils/permission_disclosure_utils.dart';
import '../../data/pdf_utils_service.dart';
import 'package:tool_hub/features/tools/docu_forge/data/docuforge_database_service.dart';
import 'package:tool_hub/features/tools/docu_forge/data/docuforge_database_service.dart';
import 'pdf_editor_screen.dart';
import 'package:go_router/go_router.dart';

class PdfViewerScreen extends StatefulWidget {
  final Document document;

  const PdfViewerScreen({super.key, required this.document});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();

  void _sharePdf() {
    final file = File(widget.document.pdfPath);
    if (file.existsSync()) {
      Share.shareXFiles([XFile(widget.document.pdfPath)], text: widget.document.name);
    }
  }

  void _backupToDrive() async {
    final file = File(widget.document.pdfPath);
    if (!file.existsSync()) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting Google Drive Sync...')));
    
    final driveService = GoogleDriveService();
    final success = await driveService.uploadPdf(file, widget.document.name);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Successfully backed up to Drive!' : 'Failed to sync. Check Google Cloud Console setup.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  Key _pdfKey = UniqueKey();

  Future<void> _appendPage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final hasPermission = await PermissionDisclosureUtils.requestWithDisclosure(
        context,
        permission: Permission.camera,
        title: 'Camera Access Needed',
        description: 'ToolHub requires camera access so you can capture new pages to add to your PDF document.',
        icon: Icons.camera_alt,
        color: Colors.blue,
      );
      if (!hasPermission) return;
    }

    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85
    );
    if (image == null) return;

    setState(() => _isProcessing = true);
    
    final originalFile = File(widget.document.pdfPath);
    final imageFile = File(image.path);
    
    final updatedFile = await PdfUtilsService.appendImageToPdf(originalFile, imageFile);
    
    if (updatedFile != null && mounted) {
      // Update page count in DB
      widget.document.pageCount += 1;
      await DocuForgeDatabaseService.instance.saveDocument(widget.document);
      
      setState(() {
        _pdfKey = UniqueKey(); // Force SfPdfViewer to reload the file
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Page added successfully!')));
    } else {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add page')));
      }
    }
  }

  void _showAddPageBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Picture'),
                onTap: () {
                  Navigator.pop(ctx);
                  _appendPage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _appendPage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      }
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2563EB),
          title: Text(
            widget.document.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
          IconButton(
            icon: const Icon(Icons.edit_document),
            onPressed: () async {
              final result = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => PdfEditorScreen(document: widget.document))
              );
              // If editor made changes, reload PDF
              if (result == true && mounted) {
                setState(() {
                  _pdfKey = UniqueKey();
                });
              }
            },
            tooltip: 'Edit Pages',
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: _backupToDrive,
            tooltip: 'Backup to Google Drive',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePdf,
            tooltip: 'Share File',
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder(
            future: Future.delayed(const Duration(milliseconds: 300)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
              }
              return SfPdfViewer.file(
                File(widget.document.pdfPath),
                key: _pdfKey,
                controller: _pdfViewerController,
                canShowScrollHead: false,
                canShowScrollStatus: false,
              );
            }
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
                    Text('Adding Page...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _showAddPageBottomSheet,
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
        label: const Text('Add Page', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
