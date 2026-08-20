import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ocr_repository.dart';

final ocrProvider = AsyncNotifierProviderFamily<OcrNotifier, Map<String, dynamic>?, String>(
  OcrNotifier.new,
);

class OcrNotifier extends FamilyAsyncNotifier<Map<String, dynamic>?, String> {
  @override
  Future<Map<String, dynamic>?> build(String arg) async {
    // Initial state is null (no extraction done yet)
    return null;
  }

  Future<void> extractData() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ocrRepositoryProvider);
      final result = await repository.extractDocument(arg);
      state = AsyncData(result);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }
}
