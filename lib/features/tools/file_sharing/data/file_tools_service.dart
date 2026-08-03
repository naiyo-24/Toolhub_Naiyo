import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import 'package:cross_file/cross_file.dart';

class FileToolsService {
  final Dio _dio;

  FileToolsService() : _dio = ApiClient().dio;

  Future<Map<String, dynamic>> extractZip(XFile file, {String? targetFile}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
      if (targetFile != null) 'target_file': targetFile,
    });
    
    // If targetFile is provided, the backend returns the extracted file bytes.
    // If not provided, it returns JSON of contents.
    final options = targetFile != null ? Options(responseType: ResponseType.bytes) : Options(responseType: ResponseType.json);
    
    final response = await _dio.post('/file-tools/zip/extract', data: formData, options: options);
    
    if (targetFile != null) {
      return {'bytes': response.data as List<int>, 'filename': targetFile};
    }
    
    return response.data;
  }

  Future<Uint8List> createZip(List<XFile> files) async {
    final formData = FormData();
    for (var file in files) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(file.path, filename: file.name),
      ));
    }
    
    final response = await _dio.post(
      '/file-tools/zip/create',
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );
    
    return Uint8List.fromList(response.data);
  }

  Future<Uint8List> compressImage(XFile file, int quality, {int? targetSizeKb}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
      'quality': quality,
    });
    
    if (targetSizeKb != null) {
      formData.fields.add(MapEntry('target_size_kb', targetSizeKb.toString()));
    }

    final response = await _dio.post(
      '/file-tools/image/compress',
      data: formData,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    
    return Uint8List.fromList(response.data);
  }

  Future<Uint8List> compressPdf(XFile file, int quality, {int? targetSizeKb, bool extremeMode = false}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
      'quality': quality,
      if (targetSizeKb != null) 'target_size_kb': targetSizeKb,
      'extreme_mode': extremeMode,
    });

    final response = await _dio.post(
      '/file-tools/pdf/compress',
      data: formData,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
        validateStatus: (status) => status! < 500,
      ),
    );
    
    return Uint8List.fromList(response.data);
  }

  Future<Uint8List> protectPdf(XFile file, String password) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
      'password': password,
    });
    
    final response = await _dio.post(
      '/file-tools/pdf/protect',
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );
    
    return Uint8List.fromList(response.data);
  }

  Future<Uint8List> mergePdf(List<XFile> files) async {
    final formData = FormData();
    for (var file in files) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(file.path, filename: file.name),
      ));
    }
    
    final response = await _dio.post(
      '/file-tools/pdf/merge',
      data: formData,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    
    return Uint8List.fromList(response.data);
  }

  Future<Map<String, dynamic>> extractOcr(XFile file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    
    final response = await _dio.post('/file-tools/ocr', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> extractHandwritingOcr(XFile file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    
    // Increased timeout for handwriting since model loading/processing is slow
    final response = await _dio.post(
      '/file-tools/ocr/handwriting', 
      data: formData,
      options: Options(receiveTimeout: const Duration(minutes: 5)),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> findDuplicates(List<XFile> files) async {
    final formData = FormData();
    for (var file in files) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(file.path, filename: file.name),
      ));
    }
    
    final response = await _dio.post('/file-tools/analyze/duplicates', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> analyzeStorage(List<XFile> files) async {
    final formData = FormData();
    for (var file in files) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(file.path, filename: file.name),
      ));
    }
    
    final response = await _dio.post('/file-tools/analyze/storage', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> shareFile(XFile file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    
    final response = await _dio.post('/file-tools/share/upload', data: formData);
    return response.data;
  }
}
