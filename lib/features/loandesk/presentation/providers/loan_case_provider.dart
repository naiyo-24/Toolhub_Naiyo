import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/loan_case.dart';

final loanCaseProvider = StateNotifierProvider<LoanCaseNotifier, List<LoanCase>>((ref) {
  return LoanCaseNotifier();
});

class LoanCaseNotifier extends StateNotifier<List<LoanCase>> {
  LoanCaseNotifier() : super([]) {
    // Seed with mock data
    state = [
      LoanCase(
        id: 'LD-2026-000145',
        customerId: 'CUST-001',
        customerName: 'John Doe',
        loanType: 'Business Loan',
        amount: 2500000,
        status: 'Documents Pending',
        applicationDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      LoanCase(
        id: 'LD-2026-000144',
        customerId: 'CUST-002',
        customerName: 'Jane Smith',
        loanType: 'MSME Loan',
        amount: 1000000,
        status: 'Completed',
        applicationDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  void addLoanCase(LoanCase loanCase) {
    state = [loanCase, ...state];
  }

  List<LoanCase> searchCases(String query) {
    if (query.isEmpty) return state;
    
    final lowerQuery = query.toLowerCase();
    return state.where((c) {
      return c.customerName.toLowerCase().contains(lowerQuery) || 
             c.id.toLowerCase().contains(lowerQuery) ||
             c.loanType.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
