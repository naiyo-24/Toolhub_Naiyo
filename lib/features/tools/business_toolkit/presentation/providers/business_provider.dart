import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/business_service.dart';

final businessServiceProvider = Provider<BusinessService>((ref) {
  return BusinessService();
});
