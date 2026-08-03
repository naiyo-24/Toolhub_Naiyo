import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tool_hub/core/api/api_config.dart';

class TravelService {
  Future<Map<String, dynamic>> submit(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
