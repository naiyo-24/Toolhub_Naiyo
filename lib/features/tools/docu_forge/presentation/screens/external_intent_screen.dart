import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uri_to_file/uri_to_file.dart';
import '../../data/models/document_model.dart';
import '../../data/docuforge_database_service.dart';
import 'dart:io';

class ExternalIntentScreen extends StatefulWidget {
  final String uri;
  const ExternalIntentScreen({super.key, required this.uri});

  @override
  State<ExternalIntentScreen> createState() => _ExternalIntentScreenState();
}

class _ExternalIntentScreenState extends State<ExternalIntentScreen> {
  @override
  void initState() {
    super.initState();
    _processUri();
  }

  Future<void> _processUri() async {
    try {
      // Resolve content:// to a temporary File
      File file = await toFile(widget.uri);
      
      final docName = file.path.split('/').last;
      final tempDoc = Document()
        ..name = docName
        ..pdfPath = file.path
        ..thumbnailPath = '' // Fix LateInitializationError
        ..fileSize = file.lengthSync()
        ..pageCount = 1
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
        
      // Save it to the database so it appears in "Recent Documents"
      await DocuForgeDatabaseService.instance.saveDocument(tempDoc);

      if (mounted) {
        context.go('/pdf-viewer', extra: tempDoc);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open external file: $e')));
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
