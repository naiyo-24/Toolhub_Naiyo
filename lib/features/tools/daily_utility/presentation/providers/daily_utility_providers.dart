import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/daily_utility_service.dart';

final dailyUtilityServiceProvider = Provider<DailyUtilityService>((ref) {
  return DailyUtilityService();
});
