import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/student_toolkit_service.dart';

final studentToolkitServiceProvider = Provider<StudentToolkitService>((ref) {
  return StudentToolkitService();
});
