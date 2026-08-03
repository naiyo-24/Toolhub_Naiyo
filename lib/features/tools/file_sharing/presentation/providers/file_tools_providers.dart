import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/file_tools_service.dart';

final fileToolsServiceProvider = Provider<FileToolsService>((ref) {
  return FileToolsService();
});
