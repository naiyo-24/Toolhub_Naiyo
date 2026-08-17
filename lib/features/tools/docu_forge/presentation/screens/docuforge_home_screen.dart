import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'scanner_screen.dart';
import 'pdf_viewer_screen.dart';
import '../providers/docuforge_providers.dart';
import '../../data/docuforge_database_service.dart';
import 'pdf_editor_screen.dart';
import '../../data/models/folder_model.dart';
import 'folder_documents_screen.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'utilities/merge_pdfs_screen.dart';
import 'utilities/images_to_pdf_screen.dart';
import 'utilities/pdf_to_image_screen.dart';
import 'utilities/pdf_security_screen.dart';
import 'utilities/watermark_pdf_screen.dart';
import 'utilities/ocr_extract_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'utilities/split_pdf_screen.dart';
import '../../data/models/document_model.dart';
import 'id_card_generator_screen.dart';
import 'ats_checker_screen.dart';
import 'cover_letter_form_screen.dart';
import 'resume_builder_form_screen.dart';
import 'utilities/pdf_converter_screen.dart';
import '../../../file_sharing/presentation/screens/pdf_compressor_screen.dart';

class DocuForgeHomeScreen extends ConsumerWidget {
  const DocuForgeHomeScreen({super.key});

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController _folderNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Folder'),
          content: TextField(
            controller: _folderNameController,
            decoration: const InputDecoration(hintText: 'Folder Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = _folderNameController.text.trim();
                if (name.isNotEmpty) {
                  final newFolder = Folder()
                    ..name = name
                    ..createdAt = DateTime.now();
                  await DocuForgeDatabaseService.instance.saveFolder(newFolder);
                  ref.invalidate(allFoldersProvider);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteFolderDialog(BuildContext context, WidgetRef ref, Folder folder) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Folder?'),
          content: Text('Are you sure you want to delete "${folder.name}"? Documents inside it will NOT be deleted, they will just be removed from this folder.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Remove folder reference from all documents inside this folder
                final docsInFolder = await DocuForgeDatabaseService.instance.getDocumentsByFolder(folder.id.toString());
                for (var doc in docsInFolder) {
                  doc.folderId = null;
                  await DocuForgeDatabaseService.instance.saveDocument(doc);
                }
                // Delete the folder itself
                await DocuForgeDatabaseService.instance.deleteFolder(folder.id);
                
                ref.invalidate(allFoldersProvider);
                ref.invalidate(recentDocumentsProvider);
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Folder deleted')));
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showDocumentOptions(BuildContext context, WidgetRef ref, Document doc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Share PDF'),
                onTap: () {
                  Navigator.pop(context);
                  Share.shareXFiles([XFile(doc.pdfPath)], text: 'Sharing ${doc.name}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.orange),
                title: const Text('Save to Device'),
                onTap: () {
                  Navigator.pop(context);
                  _saveToDevice(context, doc);
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_move, color: Colors.purple),
                title: const Text('Move to Folder'),
                onTap: () {
                  Navigator.pop(context);
                  _showMoveToFolderDialog(context, ref, doc);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.green),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, ref, doc);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context, ref, doc);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveToDevice(BuildContext context, Document doc) async {
    try {
      final file = File(doc.pdfPath);
      final bytes = await file.readAsBytes();

      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF',
        fileName: doc.name,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );

      if (outputPath != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved successfully!')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  void _showMoveToFolderDialog(BuildContext context, WidgetRef ref, Document doc) {
    final foldersAsync = ref.read(allFoldersProvider);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Move to Folder'),
          content: SizedBox(
            width: double.maxFinite,
            child: foldersAsync.when(
              data: (folders) {
                if (folders.isEmpty) {
                  return const Text('No folders created yet. Create a folder first.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return ListTile(
                      leading: const Icon(Icons.folder, color: Color(0xFFF59E0B)),
                      title: Text(folder.name),
                      onTap: () async {
                        doc.folderId = folder.id.toString();
                        doc.updatedAt = DateTime.now();
                        await DocuForgeDatabaseService.instance.saveDocument(doc);
                        ref.invalidate(recentDocumentsProvider);
                        ref.invalidate(documentsByFolderProvider(folder.id.toString())); // Invalidate the cache for this folder so it updates!
                        
                        if (context.mounted) Navigator.pop(context);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Moved to ${folder.name}')));
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const Text('Failed to load folders'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Document doc) {
    final TextEditingController _nameController = TextEditingController(text: doc.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Document'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'New Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newName = _nameController.text.trim();
                if (newName.isNotEmpty && newName != doc.name) {
                  doc.name = newName.endsWith('.pdf') ? newName : '$newName.pdf';
                  doc.updatedAt = DateTime.now();
                  await DocuForgeDatabaseService.instance.saveDocument(doc);
                  ref.invalidate(recentDocumentsProvider);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Document doc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Document?'),
          content: Text('Are you sure you want to delete ${doc.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await DocuForgeDatabaseService.instance.deleteDocument(doc.id);
                try {
                  if (doc.pdfPath.isNotEmpty) File(doc.pdfPath).deleteSync();
                  if (doc.thumbnailPath.isNotEmpty) File(doc.thumbnailPath).deleteSync();
                } catch (e) {
                  debugPrint('Error deleting files: $e');
                }
                ref.invalidate(recentDocumentsProvider);
                if (context.mounted) Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentDocsAsync = ref.watch(recentDocumentsProvider);
    final allFoldersAsync = ref.watch(allFoldersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB), // Very light off-white
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Neo-Brutalist Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4081), // Pink color from screenshot
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(2, 2),
                                blurRadius: 0,
                              )
                            ],
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Header Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'ToolHub PDF ',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Suite',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'MANAGE AND SCAN YOUR DOCUMENTS',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                const Text(
                  'Welcome to your workspace',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Scan Document Hero Card (Neo-Brutalism)
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen())).then((_) {
                      ref.invalidate(recentDocumentsProvider);
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(4, 4),
                          blurRadius: 0,
                        )
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.document_scanner_rounded, size: 40, color: Colors.white),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan Document',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Camera, auto-crop, batch mode',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                const Text(
                  'PDF Utilities',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: [
                    _buildPdfTool(context, ref, Icons.file_open_rounded, 'Open PDF', const Color(0xFFF97316)),
                    _buildPdfTool(context, ref, Icons.low_priority_rounded, 'Rearrange', const Color(0xFF10B981)),
                    _buildPdfTool(context, ref, Icons.image_rounded, 'Images to PDF', const Color(0xFFEC4899)),
                    _buildPdfTool(context, ref, Icons.merge_type_rounded, 'Merge', const Color(0xFF8B5CF6)),
                    _buildPdfTool(context, ref, Icons.call_split_rounded, 'Split', const Color(0xFFEAB308)),
                    _buildPdfTool(context, ref, Icons.lock_outline_rounded, 'Password', const Color(0xFFEF4444)),
                    _buildPdfTool(context, ref, Icons.lock_open_rounded, 'Unlock PDF', const Color(0xFF14B8A6)),
                    _buildPdfTool(context, ref, Icons.branding_watermark_rounded, 'Watermark', const Color(0xFF06B6D4)),
                    _buildPdfTool(context, ref, Icons.document_scanner_rounded, 'OCR Extract', const Color(0xFF3B82F6)),
                    _buildPdfTool(context, ref, Icons.contact_page_rounded, 'Resume', const Color(0xFFF59E0B)),
                    _buildPdfTool(context, ref, Icons.fact_check_rounded, 'ATS Check', const Color(0xFF6366F1)),
                    _buildPdfTool(context, ref, Icons.mark_email_read_rounded, 'Cover Letter', const Color(0xFFEC4899)),
                    _buildPdfTool(context, ref, Icons.compress_rounded, 'Compress PDF', const Color(0xFFF87171)),
                    _buildPdfTool(context, ref, Icons.image_rounded, 'PDF to Image', const Color(0xFF4ADE80)),
                    _buildPdfTool(context, ref, Icons.description_rounded, 'Word to PDF', const Color(0xFF60A5FA)),
                    _buildPdfTool(context, ref, Icons.picture_as_pdf_rounded, 'PDF to Word', const Color(0xFF34D399)),
                    _buildPdfTool(context, ref, Icons.table_chart_rounded, 'Excel to PDF', const Color(0xFFFBBF24)),
                    _buildPdfTool(context, ref, Icons.grid_on_rounded, 'PDF to Excel', const Color(0xFF2DD4BF)),
                    _buildPdfTool(context, ref, Icons.slideshow_rounded, 'PPT to PDF', const Color(0xFFF472B6)),
                    _buildPdfTool(context, ref, Icons.co_present_rounded, 'PDF to PPT', const Color(0xFF818CF8)),
                    _buildPdfTool(context, ref, Icons.table_view_rounded, 'Excel to CSV', const Color(0xFF4ADE80)),
                    _buildPdfTool(context, ref, Icons.pivot_table_chart_rounded, 'CSV to Excel', const Color(0xFF34D399)),
                    _buildPdfTool(context, ref, Icons.picture_as_pdf_rounded, 'CSV to PDF', const Color(0xFFF87171)),
                    _buildPdfTool(context, ref, Icons.badge_rounded, 'ID Card Gen', const Color(0xFFA78BFA)),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Folders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.create_new_folder, color: Colors.black),
                      onPressed: () => _showCreateFolderDialog(context, ref),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 56,
                  child: allFoldersAsync.when(
                    data: (folders) {
                      if (folders.isEmpty) {
                        return Center(
                          child: Text(
                            'No folders yet.',
                            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: folders.length,
                        itemBuilder: (context, index) {
                          final folder = folders[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FolderDocumentsScreen(folder: folder),
                                ),
                              );
                            },
                            onLongPress: () {
                              _showDeleteFolderDialog(context, ref, folder);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 16, bottom: 4), // bottom margin for shadow
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black, width: 3),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(3, 3),
                                    blurRadius: 0,
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.folder_rounded, color: Colors.black, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    folder.name, 
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => const Center(child: Text('Error loading folders')),
                  ),
                ),

                const SizedBox(height: 32),
                const Text(
                  'Recent Documents',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                recentDocsAsync.when(
                  data: (docs) {
                    if (docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No documents yet.\nScan a document to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        return GestureDetector(
                          onTap: () {
                            context.push('/pdf-viewer', extra: doc);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(4, 4),
                                  blurRadius: 0,
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.black, width: 2),
                                    image: doc.thumbnailPath.isNotEmpty
                                        ? DecorationImage(
                                            image: FileImage(File(doc.thumbnailPath)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: doc.thumbnailPath.isEmpty
                                      ? const Icon(Icons.picture_as_pdf_rounded, color: Colors.black, size: 30)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900, 
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${doc.pageCount} pages • ${DateFormat.yMMMd().format(doc.createdAt)}',
                                        style: const TextStyle(
                                          color: Colors.black87, 
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert_rounded, color: Colors.black),
                                  onPressed: () => _showDocumentOptions(context, ref, doc),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.black)),
                  error: (e, st) => const Center(child: Text('Error loading documents')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePdfToolAction(BuildContext context, WidgetRef ref, String action) async {
    try {
      if (action == 'Open PDF') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (result == null || result.files.isEmpty) return;

        final file = File(result.files.first.path!);
        final tempDoc = Document()
          ..name = file.path.split('/').last
          ..pdfPath = file.path
          ..thumbnailPath = ''
          ..fileSize = file.lengthSync()
          ..pageCount = 1
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
          
        await DocuForgeDatabaseService.instance.saveDocument(tempDoc);

        if (context.mounted) {
          context.push('/pdf-viewer', extra: tempDoc).then((_) {
            ref.invalidate(recentDocumentsProvider);
          });
        }
        return;
      }

      if (action == 'Rearrange') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (result == null || result.files.isEmpty) return;

        final file = File(result.files.first.path!);
        final tempDoc = Document()
          ..name = file.path.split('/').last
          ..pdfPath = file.path
          ..thumbnailPath = ''
          ..fileSize = file.lengthSync()
          ..pageCount = 1
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
          
        await DocuForgeDatabaseService.instance.saveDocument(tempDoc);

        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PdfEditorScreen(document: tempDoc))).then((_) {
            ref.invalidate(recentDocumentsProvider);
          });
        }
        return;
      }

      if (action == 'Images to PDF') {
        final result = await context.push<bool>('/images-to-pdf');
        if (result == true) ref.invalidate(recentDocumentsProvider);
        return;
      }

      if (action == 'Merge') {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const MergePdfsScreen()));
        if (result == true) ref.invalidate(recentDocumentsProvider);
        return;
      }

      if (action == 'OCR Extract') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OcrExtractScreen()));
        return;
      }

      if (action == 'Resume') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ResumeBuilderFormScreen()));
        return;
      }
      
      if (action == 'ATS Check') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ATSCheckerScreen()));
        return;
      }
      
      if (action == 'Cover Letter') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CoverLetterFormScreen()));
        return;
      }

      if (action == 'Split') {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SplitPdfScreen()));
        if (result == true) ref.invalidate(recentDocumentsProvider);
        return;
      }
      
      if (action == 'Password') {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PdfSecurityScreen(isUnlockMode: false)));
        if (result == true) ref.invalidate(recentDocumentsProvider);
        return;
      }

      if (action == 'Unlock PDF') {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PdfSecurityScreen(isUnlockMode: true)));
        if (result == true) ref.invalidate(recentDocumentsProvider);
        return;
      }

      if (action == 'Watermark') {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const WatermarkPdfScreen()));
        if (result == true) ref.invalidate(recentDocumentsProvider);
        return;
      }

      if (action == 'ID Card Gen') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const IdCardGeneratorScreen()));
        return;
      }

      if (action == 'Compress PDF') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PdfCompressorScreen()));
        return;
      }

      if (action == 'PDF to Image') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PdfToImageScreen()));
        return;
      }

      if (action == 'Word to PDF') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PdfConverterScreen(
          title: 'Word to PDF',
          endpoint: '/docuforge/word-to-pdf',
          allowedExtensions: const ['doc', 'docx'],
          outputExtension: 'pdf',
        )));
        return;
      }

      if (action == 'PDF to Word') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PdfConverterScreen(
          title: 'PDF to Word',
          endpoint: '/docuforge/pdf-to-word',
          allowedExtensions: const ['pdf'],
          outputExtension: 'docx',
        )));
        return;
      }

      if (action == 'Excel to PDF') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PdfConverterScreen(
          title: 'Excel to PDF',
          endpoint: '/docuforge/excel-to-pdf',
          allowedExtensions: const ['xls', 'xlsx'],
          outputExtension: 'pdf',
        )));
        return;
      }

      if (action == 'PDF to Excel') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PdfConverterScreen(
          title: 'PDF to Excel',
          endpoint: '/docuforge/pdf-to-excel',
          allowedExtensions: const ['pdf'],
          outputExtension: 'xlsx',
        )));
        return;
      }

      if (action == 'PPT to PDF') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PdfConverterScreen(
          title: 'PPT to PDF',
          endpoint: '/docuforge/ppt-to-pdf',
          allowedExtensions: const ['ppt', 'pptx'],
          outputExtension: 'pdf',
        )));
        return;
      }

      if (action == 'PDF to PPT') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PdfConverterScreen(
          title: 'PDF to PPT',
          endpoint: '/docuforge/pdf-to-ppt',
          allowedExtensions: const ['pdf'],
          outputExtension: 'pptx',
        )));
        return;
      }

      if (action == 'Excel to CSV') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PdfConverterScreen(
          title: 'Excel to CSV',
          endpoint: '/docuforge/excel-to-csv',
          allowedExtensions: const ['xls', 'xlsx'],
          outputExtension: 'csv',
        )));
        return;
      }

      if (action == 'CSV to Excel') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PdfConverterScreen(
          title: 'CSV to Excel',
          endpoint: '/docuforge/csv-to-excel',
          allowedExtensions: const ['csv'],
          outputExtension: 'xlsx',
        )));
        return;
      }

      if (action == 'CSV to PDF') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PdfConverterScreen(
          title: 'CSV to PDF',
          endpoint: '/docuforge/csv-to-pdf',
          allowedExtensions: const ['csv'],
          outputExtension: 'pdf',
        )));
        return;
      }

      // Show coming soon for tools that don't have dedicated screens yet
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$action is coming soon!')));
      }

    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildPdfTool(BuildContext context, WidgetRef ref, IconData icon, String label, Color bgColor) {
    return GestureDetector(
      onTap: () => _handlePdfToolAction(context, ref, label),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4, right: 4), // margin for shadow
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
