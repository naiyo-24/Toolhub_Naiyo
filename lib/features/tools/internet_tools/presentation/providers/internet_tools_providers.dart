import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/internet_tools_service.dart';

final internetToolsServiceProvider = Provider<InternetToolsService>((ref) {
  return InternetToolsService();
});
