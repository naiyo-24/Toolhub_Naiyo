import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/network/api_client.dart';
import 'package:tool_hub/core/network/api_client_provider.dart';

final ocrRepositoryProvider = Provider<OcrRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OcrRepository(apiClient);
});

class OcrRepository {
  final ApiClient _apiClient;

  OcrRepository(this._apiClient);

  Future<Map<String, dynamic>> extractDocument(String documentId) async {
    try {
      final response = await _apiClient.post('/ocr/document/$documentId/extract', data: {});
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to extract document: ${e.response?.data['detail'] ?? e.message}');
    }
  }
}
