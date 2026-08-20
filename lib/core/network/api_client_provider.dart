import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/network/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
