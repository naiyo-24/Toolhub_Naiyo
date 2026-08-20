import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/features/loandesk/data/repositories/case_repository.dart';
import '../../domain/entities/loan_case.dart';

final loanCaseProvider = StateNotifierProvider<LoanCaseNotifier, AsyncValue<List<LoanCase>>>((ref) {
  final caseRepository = ref.watch(caseRepositoryProvider);
  return LoanCaseNotifier(caseRepository);
});

class LoanCaseNotifier extends StateNotifier<AsyncValue<List<LoanCase>>> {
  final CaseRepository _caseRepository;

  LoanCaseNotifier(this._caseRepository) : super(const AsyncValue.loading()) {
    fetchCases();
  }

  Future<void> fetchCases() async {
    state = const AsyncValue.loading();
    try {
      final cases = await _caseRepository.getCases();
      state = AsyncValue.data(cases);
    } catch (e, stackTrace) {
      try {
        print('LoanCaseProvider Error: $e');
        print('LoanCaseProvider Stack: $stackTrace');
      } catch (_) {}
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<LoanCase> addLoanCase(Map<String, dynamic> caseData) async {
    try {
      final newCase = await _caseRepository.createCase(caseData);
      if (state.hasValue) {
        state = AsyncValue.data([newCase, ...state.value!]);
      } else {
        state = AsyncValue.data([newCase]);
      }
      return newCase;
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateCaseStatus(String id, String status) async {
    try {
      final updatedCase = await _caseRepository.updateCaseStatus(id, status);
      if (state.hasValue) {
        state = AsyncValue.data([
          for (final c in state.value!)
            if (c.id == id) updatedCase else c
        ]);
      }
    } catch (e) {
      print('LoanCaseProvider Error: $e');
    }
  }

  List<LoanCase> searchCases(String query) {
    if (!state.hasValue || query.isEmpty) return state.valueOrNull ?? [];
    
    final lowerQuery = query.toLowerCase();
    return state.value!.where((c) {
      return c.customerName.toLowerCase().contains(lowerQuery) || 
             c.id.toLowerCase().contains(lowerQuery) ||
             c.caseNumber.toLowerCase().contains(lowerQuery) ||
             c.loanType.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
