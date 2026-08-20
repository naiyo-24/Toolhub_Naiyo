import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_button.dart';

class BankAnalysisSummaryScreen extends StatelessWidget {
  final String caseId;

  const BankAnalysisSummaryScreen({
    super.key,
    required this.caseId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoanDeskTheme.background,
      appBar: AppBar(
        backgroundColor: LoanDeskTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: LoanDeskTheme.primaryBlack),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Bank Analysis',
          style: TextStyle(
            color: LoanDeskTheme.primaryBlack,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Main Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LoanDeskTheme.primaryBlack, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dark blue header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D1B2A), // Dark blue
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '6. BANK STATEMENT ANALYSIS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subtitle
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(color: LoanDeskTheme.primaryBlack),
                            children: [
                              TextSpan(
                                text: 'Summary ',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                              TextSpan(
                                text: '(From Uploaded Statement)',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // First Row (2 cols)
                        Row(
                          children: [
                            Expanded(child: _buildMetricBox('Total Credits', '₹ 98,40,000')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildMetricBox('Total Debits', '₹ 76,20,000')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Second Row (2 cols)
                        Row(
                          children: [
                            Expanded(child: _buildMetricBox('Avg. Monthly Credit', '₹ 8,20,000')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildMetricBox('Avg. Monthly Debit', '₹ 6,35,000')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Third Row (2 cols)
                        Row(
                          children: [
                            Expanded(child: _buildMetricBox('Average Balance', '₹ 3,45,000')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildMetricBox('Highest Balance', '₹ 6,80,000')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Fourth Row (3 cols)
                        Row(
                          children: [
                            Expanded(child: _buildMetricBox('Cash Deposits', '₹ 12,40,000')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildMetricBox('Cash Withdrawals', '₹ 8,10,000')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildMetricBox('Existing EMI (Monthly)', '₹ 65,500')),
                          ],
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Red Footer
                        const Center(
                          child: Text(
                            '(Analysis done by our backend engine)',
                            style: TextStyle(
                              color: LoanDeskTheme.primaryRed,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        NeoButton(
                          text: 'Next: Financial Analysis',
                          color: LoanDeskTheme.primaryBlue,
                          isFullWidth: true,
                          onPressed: () {
                            context.push('/loandesk/cases/financial-analysis/$caseId');
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: LoanDeskTheme.primaryBlack,
            ),
          ),
        ],
      ),
    );
  }
}
