import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/network/api_client.dart';
import 'package:tool_hub/core/network/api_client_provider.dart';
import 'package:tool_hub/features/loandesk/domain/entities/loan_case.dart';

final caseRepositoryProvider = Provider<CaseRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CaseRepository(apiClient);
});

class CaseRepository {
  final ApiClient _apiClient;

  CaseRepository(this._apiClient);

  Future<List<LoanCase>> getCases() async {
    try {
      final response = await _apiClient.get('/api/v1/cases');
      final List data = response.data;
      return data.map((json) => LoanCase.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch cases: ${e.response?.data['detail'] ?? e.message}');
    }
  }

  Future<LoanCase> createCase(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/v1/cases', data: data);
      return LoanCase.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create case: ${e.response?.data['detail'] ?? e.message}');
    }
  }

  Future<LoanCase> getCase(String id) async {
    try {
      final response = await _apiClient.get('/api/v1/cases/$id');
      return LoanCase.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch case: ${e.response?.data['detail'] ?? e.message}');
    }
  }

  Future<LoanCase> updateCaseStatus(String id, String status) async {
    try {
      final response = await _apiClient.patch('/api/v1/cases/$id', data: {'status': status});
      return LoanCase.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update case status: ${e.response?.data['detail'] ?? e.message}');
    }
  }
}
