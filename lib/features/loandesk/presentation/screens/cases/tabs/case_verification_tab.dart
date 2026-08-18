import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/loan_case.dart';
import '../../../theme/loandesk_theme.dart';
import '../../../widgets/neo_card.dart';
import '../../../widgets/neo_button.dart';
import '../../../providers/verification_provider.dart';

class CaseVerificationTab extends ConsumerWidget {
  final LoanCase loanCase;

  const CaseVerificationTab({super.key, required this.loanCase});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verifications = ref.watch(verificationProvider(loanCase.id));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Hub',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: verifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final module = verifications[index];
                return NeoCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            module.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          _buildStatusBadge(module.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provider: ${module.provider}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      if (module.provider == 'Manual' && module.status != 'Verified') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: NeoButton(
                                text: 'OPEN PORTAL',
                                color: LoanDeskTheme.primaryWhite,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Opening Official Government Portal...')),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: NeoButton(
                                text: 'MARK VERIFIED',
                                color: LoanDeskTheme.primaryGreen,
                                onPressed: () {
                                  ref.read(verificationProvider(loanCase.id).notifier)
                                     .updateStatus(module.id, 'Verified');
                                },
                              ),
                            ),
                          ],
                        ),
                      ] else if (module.status == 'Not Checked') ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(verificationProvider(loanCase.id).notifier)
                                 .updateStatus(module.id, 'Checking');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LoanDeskTheme.primaryBlack,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius / 2),
                              ),
                            ),
                            child: const Text('RUN CHECK', style: TextStyle(color: LoanDeskTheme.primaryWhite)),
                          ),
                        ),
                      ],
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
    Color textColor = LoanDeskTheme.primaryBlack;
    switch (status) {
      case 'Verified':
        bgColor = LoanDeskTheme.primaryGreen;
        break;
      case 'Checking':
        bgColor = LoanDeskTheme.primaryYellow;
        break;
      case 'Failed':
        bgColor = LoanDeskTheme.primaryPink;
        break;
      case 'Manual Review':
        bgColor = LoanDeskTheme.primaryBlue;
        textColor = LoanDeskTheme.primaryWhite;
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
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: textColor),
      ),
    );
  }
}
