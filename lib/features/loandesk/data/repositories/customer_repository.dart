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
      final response = await _apiClient.get('/customers');
      print('RAW API RESPONSE: ${response.data}');
      
      final List data = response.data;
      return data.map((json) {
        try {
          return Customer.fromJson(json);
        } catch (e) {
          print('FAILED TO PARSE CUSTOMER JSON: $json');
          print('PARSE ERROR: $e');
          rethrow;
        }
      }).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch customers: ${e.response?.data['detail'] ?? e.message}');
    } catch (e) {
      print('ERROR IN GETCUSTOMERS: $e');
      rethrow;
    }
  }

  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/customers', data: data);
      return Customer.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create customer: ${e.response?.data['detail'] ?? e.message}');
    }
  }

  Future<Customer> getCustomer(String id) async {
    try {
      final response = await _apiClient.get('/customers/$id');
      return Customer.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch customer: ${e.response?.data['detail'] ?? e.message}');
    }
  }
}
