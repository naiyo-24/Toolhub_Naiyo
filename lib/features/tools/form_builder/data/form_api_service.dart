import 'package:dio/dio.dart';
import '../../../../../core/api/api_client.dart';
import 'models/form_models.dart';

class FormApiService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> createForm(FormCreateModel form) async {
    try {
      final response = await _dio.post(
        '/form-builder/forms',
        data: form.toJson(),
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to create form: $e');
    }
  }

  Future<String> uploadFile(String filePath, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _dio.post('/form-builder/forms/upload', data: formData);
      return response.data['url'];
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<List<FormResponseModel>> getMyForms() async {
    try {
      final response = await _dio.get('/form-builder/forms');
      final List data = response.data;
      return data.map((json) => FormResponseModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch forms: $e');
    }
  }

  Future<FormDetailModel> getPublicForm(String formId) async {
    try {
      final response = await _dio.get('/form-builder/forms/$formId');
      return FormDetailModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load form details: $e');
    }
  }

  Future<void> submitFormResponse(String formId, Map<String, dynamic> answers, {String? email}) async {
    try {
      await _dio.post(
        '/form-builder/forms/$formId/submit',
        data: {
          'respondent_email': email,
          'answers': answers,
        },
      );
    } catch (e) {
      throw Exception('Failed to submit form: $e');
    }
  }

  Future<Map<String, dynamic>> updateForm(String formId, FormCreateModel form) async {
    try {
      final response = await _dio.put(
        '/form-builder/forms/$formId',
        data: form.toJson(),
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to update form: $e');
    }
  }

  Future<void> deleteForm(String formId) async {
    try {
      await _dio.delete('/form-builder/forms/$formId');
    } catch (e) {
      throw Exception('Failed to delete form: $e');
    }
  }

  Future<Map<String, dynamic>> getFormResponses(String formId) async {
    try {
      final response = await _dio.get('/form-builder/forms/$formId/responses');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load responses: $e');
    }
  }
}
