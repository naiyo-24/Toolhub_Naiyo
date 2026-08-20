import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/loan_case.dart';
import '../../../../../../core/api/api_config.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';

class CaseSummaryPdfScreen extends ConsumerWidget {
  final LoanCase loanCase;

  const CaseSummaryPdfScreen({super.key, required this.loanCase});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final token = authState.valueOrNull?.token ?? '';

    final String pdfUrl = '${ApiConfig.loanDeskBaseUrl}/reports/case/${loanCase.id}/summary-pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text('CAM Report: ${loanCase.applicantName}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SfPdfViewer.network(
        pdfUrl,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }
}
