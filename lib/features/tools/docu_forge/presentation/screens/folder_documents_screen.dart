import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/folder_model.dart';
import '../../data/models/document_model.dart';
import '../../data/docuforge_database_service.dart';
import '../providers/docuforge_providers.dart';
import 'pdf_viewer_screen.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'docuforge_home_screen.dart';

class FolderDocumentsScreen extends ConsumerWidget {
  final Folder folder;

  const FolderDocumentsScreen({super.key, required this.folder});

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
                onTap: () async {
                  Navigator.pop(context);
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

                    if (outputPath != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully!')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_off, color: Colors.orange),
                title: const Text('Remove from Folder'),
                onTap: () async {
                  Navigator.pop(context);
                  doc.folderId = null; // Remove from folder
                  doc.updatedAt = DateTime.now();
                  await DocuForgeDatabaseService.instance.saveDocument(doc);
                  ref.invalidate(documentsByFolderProvider(folder.id.toString()));
                  ref.invalidate(recentDocumentsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from folder')));
                  }
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

  void _showRenameDialog(BuildContext context, WidgetRef ref, Document doc) {
    final TextEditingController nameController = TextEditingController(text: doc.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Document'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'New Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty && newName != doc.name) {
                  doc.name = newName.endsWith('.pdf') ? newName : '$newName.pdf';
                  doc.updatedAt = DateTime.now();
                  await DocuForgeDatabaseService.instance.saveDocument(doc);
                  ref.invalidate(documentsByFolderProvider(folder.id.toString()));
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
                ref.invalidate(documentsByFolderProvider(folder.id.toString()));
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
    final documentsAsync = ref.watch(documentsByFolderProvider(folder.id.toString()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        title: Text(
          folder.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: documentsAsync.when(
        data: (docs) {
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'This folder is empty',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Move documents here from the home screen',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: doc.thumbnailPath.isNotEmpty && File(doc.thumbnailPath).existsSync()
                          ? Image.file(
                              File(doc.thumbnailPath),
                              width: 50,
                              height: 70,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 50,
                              height: 70,
                              color: Colors.grey[200],
                              child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                            ),
                    ),
                    title: Text(
                      doc.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${DateFormat('MMM d, yyyy').format(doc.updatedAt)} • ${doc.pageCount} pages',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showDocumentOptions(context, ref, doc),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerScreen(document: doc),
                        ),
                      ).then((_) {
                        ref.invalidate(documentsByFolderProvider(folder.id.toString()));
                        ref.invalidate(recentDocumentsProvider);
                      });
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading folder: $e')),
      ),
    );
  }
}
