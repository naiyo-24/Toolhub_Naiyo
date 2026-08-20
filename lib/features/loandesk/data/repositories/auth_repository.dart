import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tool_hub/core/network/api_client.dart';
import 'package:tool_hub/core/network/api_client_provider.dart';
import 'package:tool_hub/features/loandesk/data/models/auth_response_model.dart';
import 'package:tool_hub/features/loandesk/data/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<AuthResponseModel> loginWithGoogle(String googleIdToken) async {
    try {
      final response = await _apiClient.post(
        '/auth/login/google',
        data: {'token': googleIdToken},
      );
      
      final authResponse = AuthResponseModel.fromJson(response.data);
      
      // Save token locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', authResponse.accessToken);
      
      return authResponse;
    } on DioException catch (e) {
      throw Exception('Failed to login: ${e.response?.data['detail'] ?? e.message}');
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _apiClient.get('/auth/profile');
      var userJson = response.data as Map<String, dynamic>;
      
      try {
        final bankerResponse = await _apiClient.get('/api/v1/banker/profile');
        if (bankerResponse.data != null) {
          final bankerData = Map<String, dynamic>.from(bankerResponse.data);
          bankerData.removeWhere((key, value) => value == null);
          userJson = {...userJson, ...bankerData};
          userJson['is_profile_complete'] = true;
        }
      } catch (_) {
        // If banker profile doesn't exist or fails, just use base profile
      }
      
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw Exception('Failed to fetch user profile: ${e.response?.data['detail'] ?? e.message}');
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/v1/banker/profile', data: data);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      final errorMsg = e.response?.data['detail']?.toString() ?? e.message ?? '';
      
      // If the backend says it already exists, try to PUT (update) instead!
      // Or just fetch the profile if PUT isn't supported.
      if (errorMsg.toLowerCase().contains('already exists')) {
        try {
          final putResponse = await _apiClient.patch('/api/v1/banker/profile', data: data);
          return UserModel.fromJson(putResponse.data);
        } catch (putErr) {
           // If PUT fails (e.g. 405 Method Not Allowed), just fetch the full profile and proceed
           return await getMe();
        }
      }
      
      throw Exception('Failed to update profile: $errorMsg');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    // Call backend logout endpoint if it exists
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {
      // Ignore errors on logout
    }
  }
}
