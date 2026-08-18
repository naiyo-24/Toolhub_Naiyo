import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerificationModule {
  final String id;
  final String name;
  final String status; // "Not Checked", "Checking", "Verified", "Failed", "Manual Review"
  final String provider; // e.g., "NSDL API", "GSTN API", "Manual"

  VerificationModule({
    required this.id,
    required this.name,
    required this.status,
    required this.provider,
  });

  VerificationModule copyWith({
    String? id,
    String? name,
    String? status,
    String? provider,
  }) {
    return VerificationModule(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      provider: provider ?? this.provider,
    );
  }
}

final verificationProvider = StateNotifierProvider.family<VerificationNotifier, List<VerificationModule>, String>((ref, caseId) {
  return VerificationNotifier(caseId);
});

class VerificationNotifier extends StateNotifier<List<VerificationModule>> {
  final String caseId;

  VerificationNotifier(this.caseId) : super([]) {
    state = [
      VerificationModule(id: 'V-1', name: 'PAN Verification', status: 'Verified', provider: 'NSDL API'),
      VerificationModule(id: 'V-2', name: 'GST Verification', status: 'Verified', provider: 'GSTN API'),
      VerificationModule(id: 'V-3', name: 'Udyam Registration', status: 'Checking', provider: 'MSME API'),
      VerificationModule(id: 'V-4', name: 'Bank Details (Penny Drop)', status: 'Not Checked', provider: 'Banking API'),
      VerificationModule(id: 'V-5', name: 'MCA Company Search', status: 'Manual Review', provider: 'Manual'),
    ];
  }

  void updateStatus(String id, String newStatus) {
    state = [
      for (final module in state)
        if (module.id == id)
          module.copyWith(status: newStatus)
        else
          module
    ];
  }
}
