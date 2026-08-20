import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/network/api_client.dart';
import 'package:tool_hub/core/network/api_client_provider.dart';
import 'package:tool_hub/features/loandesk/domain/entities/customer.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CustomerRepository(apiClient);
});

class CustomerRepository {
  final ApiClient _apiClient;

  CustomerRepository(this._apiClient);

  Future<List<Customer>> getCustomers() async {
    try {
      final response = await _apiClient.get('/api/v1/customers');
      final List data = response.data;
      return data.map((json) => Customer.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch customers: ${e.response?.data['detail'] ?? e.message}');
    }
  }

  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/v1/customers', data: data);
      return Customer.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create customer: ${e.response?.data['detail'] ?? e.message}');
    }
  }

  Future<Customer> getCustomer(String id) async {
    try {
      final response = await _apiClient.get('/api/v1/customers/$id');
      return Customer.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch customer: ${e.response?.data['detail'] ?? e.message}');
    }
  }
}
