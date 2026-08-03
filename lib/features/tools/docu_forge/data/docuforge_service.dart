import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class DocuForgeService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> checkAtsScore(File resume, String jobDescription) async {
    final formData = FormData.fromMap({
      'resume': await MultipartFile.fromFile(resume.path, filename: resume.path.split('/').last),
      'job_description': jobDescription,
    });

    final response = await _apiClient.dio.post(
      '/docuforge/ats-checker',
      data: formData,
    );
    
    return response.data['ats_analysis'];
  }

  Future<String> ocrScanner(File image) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path, filename: image.path.split('/').last),
    });

    final response = await _apiClient.dio.post(
      '/docuforge/ocr-scanner',
      data: formData,
      options: Options(receiveTimeout: const Duration(minutes: 5)),
    );
    
    return response.data['extracted_text'];
  }

  // Generalized method for simple 1-file conversions
  Future<List<int>> convertFile(File file, String endpoint) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
    });

    final response = await _apiClient.dio.post(
      endpoint,
      data: formData,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    
    return response.data;
  }

  // Merge PDF takes multiple files
  Future<List<int>> mergePdf(List<File> files) async {
    final formData = FormData();
    for (var file in files) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      ));
    }

    final response = await _apiClient.dio.post(
      '/docuforge/merge-pdf',
      data: formData,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    
    return response.data;
  }

  // Image to PDF takes multiple files
  Future<List<int>> imagesToPdf(List<File> images) async {
    final formData = FormData();
    for (var file in images) {
      formData.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      ));
    }

    final response = await _apiClient.dio.post(
      '/docuforge/image-to-pdf',
      data: formData,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    
    return response.data;
  }

  // Split PDF takes a file and page numbers
  Future<List<int>> splitPdf(File file, String pageNumbers) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      'page_numbers': pageNumbers,
    });

    final response = await _apiClient.dio.post(
      '/docuforge/split-pdf',
      data: formData,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    
    return response.data;
  }

  // Compress PDF
  Future<List<int>> compressPdf(File file, int quality, {int? targetSizeKb}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      'quality': quality,
      if (targetSizeKb != null) 'target_size_kb': targetSizeKb,
      'extreme_mode': false,
    });

    final response = await _apiClient.dio.post(
      '/file-tools/pdf/compress',
      data: formData,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    
    return response.data;
  }

  // Document Scan
  Future<List<int>> documentScan(List<File> images, String scanType) async {
    final formData = FormData();
    for (var file in images) {
      formData.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      ));
    }
    
    formData.fields.add(MapEntry('scan_type', scanType));

    final response = await _apiClient.dio.post(
      '/docuforge/document-scan',
      data: formData,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    
    return response.data;
  }

  // Digital Sign
  Future<List<int>> digitalSign(File pdfFile, File signatureImage, {String position = 'bottom_right'}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(pdfFile.path, filename: pdfFile.path.split('/').last),
      'signature_image': await MultipartFile.fromFile(signatureImage.path, filename: signatureImage.path.split('/').last),
      'position': position,
    });

    final response = await _apiClient.dio.post(
      '/docuforge/digital-sign',
      data: formData,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    
    return response.data;
  }

  // Watermark PDF
  Future<Uint8List> watermarkPdf(File pdfFile, {File? watermarkImage, String? watermarkText}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(pdfFile.path, filename: pdfFile.path.split('/').last),
      });
      
      if (watermarkImage != null) {
        formData.files.add(MapEntry(
          'watermark_image', 
          await MultipartFile.fromFile(watermarkImage.path, filename: watermarkImage.path.split('/').last)
        ));
      }
      if (watermarkText != null && watermarkText.isNotEmpty) {
        formData.fields.add(MapEntry('watermark_text', watermarkText));
      }

      final response = await _apiClient.dio.post(
        '/docuforge/watermark-pdf',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      
      return response.data;
    } catch (e) {
      throw Exception('Failed to apply watermark: $e');
    }
  }
}
