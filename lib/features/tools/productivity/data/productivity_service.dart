import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tool_hub/core/api/api_config.dart';

class ProductivityService {
  Future<Map<String, dynamic>> submit(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to submit productivity tool: $e');
    }
  }

  Future<List<dynamic>> fetchList(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded.containsKey('data')) return decoded['data'];
        return [decoded];
      } else if (response.statusCode == 404 || response.statusCode == 405) {
        // Endpoint doesn't support GET or doesn't exist
        return [];
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Just return empty if we can't fetch history (some tools don't have it)
      return [];
    }
  }

  Future<void> deleteItem(String endpoint, int id) async {
    try {
      final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}$endpoint/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete');
      }
    } catch (e) {
      throw Exception('Error deleting item: $e');
    }
  }

  Future<void> updateTodoStatus(int id, bool isCompleted) async {
    try {
      final response = await http.put(Uri.parse('${ApiConfig.baseUrl}/productivity-tools/todo/$id?is_completed=$isCompleted'));
      if (response.statusCode != 200) {
        throw Exception('Failed to update');
      }
    } catch (e) {
      throw Exception('Error updating item: $e');
    }
  }

  Future<void> updateHabit(String endpoint, int id, Map<String, dynamic> habitData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}$endpoint/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(habitData),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update habit');
      }
    } catch (e) {
      throw Exception('Error updating habit: $e');
    }
  }

  Future<void> updateGoal(int id, Map<String, dynamic> goalData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/productivity-tools/goals/$id/edit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(goalData),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update goal');
      }
    } catch (e) {
      throw Exception('Error updating goal: $e');
    }
  }

  Future<void> updateNote(int id, Map<String, dynamic> noteData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/productivity-tools/notes/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(noteData),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update note');
      }
    } catch (e) {
      throw Exception('Error updating note: $e');
    }
  }

  Future<void> updateReminder(int id, Map<String, dynamic> reminderData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/productivity-tools/reminders/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reminderData),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update reminder');
      }
    } catch (e) {
      throw Exception('Error updating reminder: $e');
    }
  }

  Future<Map<String, dynamic>> uploadVoiceNote(String endpoint, String title, String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}$endpoint'));
      
      request.fields['title'] = title;
      
      var file = await http.MultipartFile.fromPath('file', filePath);
      request.files.add(file);
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload voice note: $e');
    }
  }
}
