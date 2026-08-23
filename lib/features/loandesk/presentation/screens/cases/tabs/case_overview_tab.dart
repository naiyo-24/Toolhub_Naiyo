import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/loan_case.dart';
import '../../../theme/loandesk_theme.dart';
import '../../../widgets/neo_card.dart';
import '../../../widgets/neo_button.dart';
import '../../reports/case_summary_pdf_screen.dart';
import '../../../providers/document_provider.dart';

class CaseOverviewTab extends ConsumerWidget {
  final LoanCase loanCase;
  
  const CaseOverviewTab({super.key, required this.loanCase});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsState = ref.watch(documentProvider(loanCase.id));
    
    String actionTitle = 'Next Action Required';
    String actionDesc = 'Please collect and verify the pending documents from the Documents tab.';
    Color cardColor = LoanDeskTheme.primaryYellow;
    
    if (docsState.value != null) {
      final docs = docsState.value!;
      final hasPending = docs.any((d) => d.status == 'Pending');
      final hasUploaded = docs.any((d) => d.status == 'Uploaded');
      
      if (hasUploaded) {
        actionTitle = 'Verification Pending';
        actionDesc = 'New documents have been uploaded. Please go to the Documents tab and submit them for verification.';
        cardColor = LoanDeskTheme.primaryYellow;
      } else if (!hasPending && docs.isNotEmpty) {
        actionTitle = 'Ready for Analysis';
        actionDesc = 'All documents are verified. You can now run the AI Analysis.';
        cardColor = LoanDeskTheme.primaryGreen;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeoCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Case Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Customer', loanCase.customerName),
                const SizedBox(height: 8),
                _buildInfoRow('Loan Type', loanCase.loanType),
                const SizedBox(height: 8),
                _buildInfoRow('Amount Requested', '₹${loanCase.amount.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildInfoRow('Application Date', '${loanCase.applicationDate.day}/${loanCase.applicationDate.month}/${loanCase.applicationDate.year}'),
                const SizedBox(height: 8),
                _buildInfoRow('Current Status', loanCase.status, isStatus: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          NeoButton(
            text: 'GENERATE CAM REPORT',
            isFullWidth: true,
            color: LoanDeskTheme.primaryPink,
            textColor: LoanDeskTheme.primaryBlack,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CaseSummaryPdfScreen(loanCase: loanCase),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          NeoCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: cardColor,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actionTitle,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      Text(
                        actionDesc,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        Flexible(
          child: isStatus 
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: LoanDeskTheme.primaryWhite,
                  borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
                  border: Border.all(color: LoanDeskTheme.primaryBlack, width: 2),
                ),
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              )
            : Text(
                value,
                style: const TextStyle(
                  color: LoanDeskTheme.primaryBlack,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                textAlign: TextAlign.right,
              ),
        ),
      ],
    );
  }
}
