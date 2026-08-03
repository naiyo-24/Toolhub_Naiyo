import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class FinanceService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> calculate(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        '/finance-tools$endpoint',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? e.message);
      }
      throw Exception('Failed to calculate: $e');
    }
  }
}
