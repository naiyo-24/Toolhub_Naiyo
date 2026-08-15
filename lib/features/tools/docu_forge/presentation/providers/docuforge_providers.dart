import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/document_model.dart';
import '../../data/models/folder_model.dart';
import '../../data/docuforge_database_service.dart';

final recentDocumentsProvider = FutureProvider<List<Document>>((ref) async {
  return await DocuForgeDatabaseService.instance.getRecentDocuments();
});

final allFoldersProvider = FutureProvider<List<Folder>>((ref) async {
  return await DocuForgeDatabaseService.instance.getAllFolders();
});

final documentsByFolderProvider = FutureProvider.family<List<Document>, String>((ref, folderId) async {
  return await DocuForgeDatabaseService.instance.getDocumentsByFolder(folderId);
});
