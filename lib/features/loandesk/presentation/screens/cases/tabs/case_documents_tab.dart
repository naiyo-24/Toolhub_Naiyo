import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/loan_case.dart';
import '../../../theme/loandesk_theme.dart';
import '../../../widgets/neo_card.dart';
import '../../../providers/document_provider.dart';

class CaseDocumentsTab extends ConsumerWidget {
  final LoanCase loanCase;
  
  const CaseDocumentsTab({super.key, required this.loanCase});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the documents for this specific case
    final documents = ref.watch(documentProvider(loanCase.id));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Document Checklist',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/loandesk/cases/vault/${loanCase.id}');
                },
                icon: const Icon(Icons.folder, size: 16, color: LoanDeskTheme.primaryWhite),
                label: const Text(
                  'View Vault',
                  style: TextStyle(color: LoanDeskTheme.primaryWhite, fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LoanDeskTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius / 2),
                    side: const BorderSide(color: LoanDeskTheme.primaryBlack, width: 2),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: documents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final doc = documents[index];
                return NeoCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildStatusBadge(doc.status),
                          ],
                        ),
                      ),
                      if (doc.status != 'Received')
                        ElevatedButton.icon(
                          onPressed: () {
                            context.push('/loandesk/scanner', extra: {
                              'caseId': loanCase.id,
                              'docId': doc.id,
                              'docName': doc.name,
                            });
                          },
                          icon: const Icon(Icons.document_scanner, size: 16, color: LoanDeskTheme.primaryWhite),
                          label: const Text(
                            'Scan',
                            style: TextStyle(color: LoanDeskTheme.primaryWhite, fontWeight: FontWeight.w900),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LoanDeskTheme.primaryBlack,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius / 2),
                            ),
                            elevation: 0,
                          ),
                        )
                      else
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.remove_red_eye, color: LoanDeskTheme.primaryBlue),
                          tooltip: 'View Document',
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    switch (status) {
      case 'Received':
        bgColor = LoanDeskTheme.primaryGreen;
        break;
      case 'Processing':
        bgColor = LoanDeskTheme.primaryYellow;
        break;
      default:
        bgColor = LoanDeskTheme.primaryWhite;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
        border: Border.all(color: LoanDeskTheme.primaryBlack, width: 2),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
      ),
    );
  }
}
