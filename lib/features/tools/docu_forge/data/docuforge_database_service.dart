import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/document_model.dart';
import 'models/folder_model.dart';
import 'pdf_utils_service.dart';
import 'dart:io';

class DocuForgeDatabaseService {
  static late Isar _isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [DocumentSchema, FolderSchema],
      directory: dir.path,
    );
  }

  static final DocuForgeDatabaseService _instance = DocuForgeDatabaseService._internal();
  DocuForgeDatabaseService._internal();

  static DocuForgeDatabaseService get instance => _instance;

  // Documents
  Future<void> saveDocument(Document document) async {
    if (document.thumbnailPath.isEmpty && document.pdfPath.isNotEmpty) {
      document.thumbnailPath = await PdfUtilsService.generatePdfThumbnail(File(document.pdfPath));
    }

    await _isar.writeTxn(() async {
      await _isar.documents.put(document);
    });
  }

  Future<void> deleteDocument(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.documents.delete(id);
    });
  }

  Future<List<Document>> getAllDocuments() async {
    return await _isar.documents.where().sortByUpdatedAtDesc().findAll();
  }

  Future<List<Document>> getRecentDocuments() async {
    return await _isar.documents.filter().folderIdIsNull().sortByUpdatedAtDesc().limit(10).findAll();
  }

  Future<List<Document>> getDocumentsByFolder(String folderId) async {
    return await _isar.documents.filter().folderIdEqualTo(folderId).sortByUpdatedAtDesc().findAll();
  }

  // Folders
  Future<void> saveFolder(Folder folder) async {
    await _isar.writeTxn(() async {
      await _isar.folders.put(folder);
    });
  }

  Future<void> deleteFolder(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.folders.delete(id);
    });
  }

  Future<List<Folder>> getAllFolders() async {
    return await _isar.folders.where().findAll();
  }
}
