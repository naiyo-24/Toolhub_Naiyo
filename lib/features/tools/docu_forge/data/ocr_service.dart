import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_config.dart';

class OcrService {
  static Future<String> extractTextFromImage(File imageFile) async {
    try {
      final String backendUrl = '${ApiConfig.baseUrl}/extract-text';
      var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
      
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path)
      );

      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var decoded = jsonDecode(responseData);
        return decoded['text'] ?? '';
      } else {
        debugPrint('Backend OCR Error: Status ${response.statusCode}');
        return '';
      }
    } catch (e) {
      debugPrint('OCR Exception: $e');
      return '';
    }
  }
}
