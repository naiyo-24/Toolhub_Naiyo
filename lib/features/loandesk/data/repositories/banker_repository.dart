import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/network/api_client.dart';
import 'package:tool_hub/core/network/api_client_provider.dart';
import 'package:tool_hub/features/loandesk/data/models/banker_profile_model.dart';

final bankerRepositoryProvider = Provider<BankerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BankerRepository(apiClient);
});

class BankerRepository {
  final ApiClient _apiClient;

  BankerRepository(this._apiClient);

  Future<BankerProfileModel> getProfile() async {
    try {
      final response = await _apiClient.get('/banker/profile');
      return BankerProfileModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Profile not found');
      }
      throw Exception('Failed to fetch banker profile: ${e.response?.data['detail'] ?? e.message}');
    }
  }

  Future<BankerProfileModel> createProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/banker/profile', data: data);
      return BankerProfileModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create banker profile: ${e.response?.data['detail'] ?? e.message}');
    }
  }

  Future<List<OrganizationModel>> getOrganizations() async {
    try {
      final response = await _apiClient.get('/organizations');
      final List data = response.data;
      return data.map((json) => OrganizationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch organizations: ${e.response?.data['detail'] ?? e.message}');
    }
  }
}
