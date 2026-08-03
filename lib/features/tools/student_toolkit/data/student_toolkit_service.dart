import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class StudentToolkitService {
  final Dio _dio;

  StudentToolkitService() : _dio = ApiClient().dio;

  Future<Map<String, dynamic>> calculateCgpa(List<Map<String, dynamic>> semesters) async {
    final response = await _dio.post('/student-toolkit/cgpa-calculator', data: {
      'semesters': semesters,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> calculateSgpa(List<Map<String, dynamic>> courses) async {
    final response = await _dio.post('/student-toolkit/sgpa-calculator', data: {
      'courses': courses,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> calculateAttendance(int totalClasses, int classesAttended, double targetPercentage) async {
    final response = await _dio.post('/student-toolkit/attendance-calculator', data: {
      'total_classes': totalClasses,
      'classes_attended': classesAttended,
      'target_percentage': targetPercentage,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> examCountdown(String examDate) async {
    final response = await _dio.post('/student-toolkit/exam-countdown', data: {
      'exam_date': examDate,
    });
    return response.data;
  }
}
