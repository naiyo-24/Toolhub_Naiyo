import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tool_hub/core/api/api_config.dart';

class SocialService {
  Future<Map<String, dynamic>> calculate(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/social-tools$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to process request: $e');
    }
  }
}
