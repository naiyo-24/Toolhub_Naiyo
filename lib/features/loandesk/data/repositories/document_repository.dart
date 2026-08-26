import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/network/api_client.dart';
import 'package:tool_hub/core/network/api_client_provider.dart';
import '../models/document_model.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DocumentRepository(apiClient);
});

class DocumentRepository {
  final ApiClient _apiClient;

  DocumentRepository(this._apiClient);

  Future<List<DocumentModel>> getCaseDocuments(String caseId) async {
    try {
      final response = await _apiClient.get('/documents/case/$caseId');
      final List data = response.data;
      return data.map((json) => DocumentModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch documents: ${e.response?.data['detail'] ?? e.message}');
    }
  }

  Future<DocumentModel> uploadDocument({
    required String caseId,
    required String documentType,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
  }) async {
    try {
      MultipartFile file;
      
      if (kIsWeb) {
        if (fileBytes == null) throw Exception('File bytes are required for web upload');
        file = MultipartFile.fromBytes(fileBytes, filename: fileName);
      } else {
        if (filePath == null) throw Exception('File path is required for native upload');
        file = await MultipartFile.fromFile(filePath, filename: fileName);
      }

      FormData formData = FormData.fromMap({
        'case_id': caseId,
        'document_type': documentType,
        'file': file,
      });

      final response = await _apiClient.post(
        '/documents/upload',
        data: formData,
      );
      
      return DocumentModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to upload document: ${e.response?.data['detail'] ?? e.message}');
    }
  }

  Future<Map<String, dynamic>> getDocumentAccess(int documentId) async {
    try {
      final response = await _apiClient.get('/documents/$documentId/access');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to get document access: ${e.response?.data['detail'] ?? e.message}');
    }
  }
}
