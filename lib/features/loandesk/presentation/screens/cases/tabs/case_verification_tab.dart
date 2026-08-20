import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/loandesk_theme.dart';
import '../../../widgets/neo_card.dart';
import '../../../widgets/neo_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/loan_case.dart';
import '../../../providers/loan_case_provider.dart';

class CaseVerificationTab extends ConsumerStatefulWidget {
  final LoanCase loanCase;

  const CaseVerificationTab({
    super.key,
    required this.loanCase,
  });

  @override
  ConsumerState<CaseVerificationTab> createState() => _CaseVerificationTabState();
}

class _CaseVerificationTabState extends ConsumerState<CaseVerificationTab> {

  Future<void> _launchUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
            backgroundColor: LoanDeskTheme.primaryRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Hub',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: LoanDeskTheme.primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use the official government portals below to verify customer details and documents.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildPortalCard(
            context,
            title: 'GST Portal',
            subtitle: 'Search, Validate & Download GST Data',
            url: 'https://www.gst.gov.in',
            color: LoanDeskTheme.primaryYellow,
            icon: Icons.receipt_long,
          ),
          const SizedBox(height: 16),
          
          _buildPortalCard(
            context,
            title: 'Udyam / MSME Portal',
            subtitle: 'Verify & Download Udyam Certificate',
            url: 'https://udyamregistration.gov.in',
            color: LoanDeskTheme.primaryBlue,
            icon: Icons.factory,
          ),
          const SizedBox(height: 16),
          
          _buildPortalCard(
            context,
            title: 'Income Tax Portal',
            subtitle: 'ITR & Tax Documents',
            url: 'https://www.incometax.gov.in',
            color: LoanDeskTheme.primaryGreen,
            icon: Icons.account_balance,
          ),
          const SizedBox(height: 16),
          
          _buildPortalCard(
            context,
            title: 'MCA Portal',
            subtitle: 'Company Details & CIN',
            url: 'https://www.mca.gov.in',
            color: LoanDeskTheme.primaryPink,
            icon: Icons.corporate_fare,
          ),
          const SizedBox(height: 16),
          
          _buildPortalCard(
            context,
            title: 'IFSC / Bank Info',
            subtitle: 'Verify Bank Branch details',
            url: 'https://ifsc.razorpay.com',
            color: LoanDeskTheme.primaryYellow,
            icon: Icons.account_balance_wallet,
          ),
          const SizedBox(height: 16),
          
          _buildPortalCard(
            context,
            title: 'RBI',
            subtitle: 'Policies & Guidelines',
            url: 'https://www.rbi.org.in',
            color: LoanDeskTheme.primaryBlue,
            icon: Icons.policy,
          ),
          
          if (widget.loanCase.status == 'Under Verification' || widget.loanCase.status == 'In Progress')
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: NeoButton(
                text: 'MARK AS VERIFIED',
                isFullWidth: true,
                color: LoanDeskTheme.primaryGreen,
                onPressed: () async {
                  try {
                    await ref.read(loanCaseProvider.notifier).updateCaseStatus(widget.loanCase.id, 'Verified');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Verification completed successfully!'),
                          backgroundColor: LoanDeskTheme.primaryGreen,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: LoanDeskTheme.primaryRed,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          const SizedBox(height: 80), // bottom padding
        ],
      ),
    );
  }

  Widget _buildPortalCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String url,
    required Color color,
    required IconData icon,
  }) {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: LoanDeskTheme.primaryWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: LoanDeskTheme.primaryBlack, width: 2),
                ),
                child: Icon(icon, color: LoanDeskTheme.primaryBlack),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: LoanDeskTheme.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NeoButton(
            text: 'OPEN PORTAL',
            isFullWidth: true,
            color: color,
            onPressed: () => _launchUrl(url, context),
          ),
        ],
      ),
    );
  }
}
