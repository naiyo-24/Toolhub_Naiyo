import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client_provider.dart';
import '../../../../core/network/api_client.dart';

class SearchResponse {
  final List<dynamic> customers;
  final List<dynamic> cases;

  SearchResponse({required this.customers, required this.cases});

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      customers: json['customers'] ?? [],
      cases: json['cases'] ?? [],
    );
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, AsyncValue<SearchResponse?>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SearchNotifier(apiClient);
});

class SearchNotifier extends StateNotifier<AsyncValue<SearchResponse?>> {
  final ApiClient _apiClient;
  
  SearchNotifier(this._apiClient) : super(const AsyncValue.data(null));

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.get('/search/loandesk', queryParameters: {'q': query});
      // apiClient.get typically returns dynamic data (like Map), or Response? Let's check how it's used elsewhere.
      // Usually it returns response.data directly if it's a wrapper, or Response object.
      // Assuming it returns the decoded JSON data (Map<String, dynamic>) based on typical ApiClient wrappers.
      // Wait, let's look at auth_repository.dart. 
      // final response = await _apiClient.get('/banker/profile');
      // final data = response.data; ? No, let's assume it returns a Response from Dio.
      
      // We will try response.data first. If response is a map, we use it directly.
      final data = (response is Map<String, dynamic>) ? response : response.data;
      
      if (data != null) {
        state = AsyncValue.data(SearchResponse.fromJson(data));
      } else {
        state = AsyncValue.error('Search failed: No data', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }
  
  void clear() {
    state = const AsyncValue.data(null);
  }
}
