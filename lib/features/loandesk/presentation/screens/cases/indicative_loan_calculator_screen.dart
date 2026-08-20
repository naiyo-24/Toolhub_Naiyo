import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_button.dart';

class IndicativeLoanCalculatorScreen extends StatelessWidget {
  final String caseId;

  const IndicativeLoanCalculatorScreen({
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
          'Loan Calculator',
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
            // Container with Header and Content
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
                      '8. LOAN CALCULATOR (INDICATIVE)',
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
                        // Input Fields
                        Row(
                          children: [
                            Expanded(child: _buildInputField('Proposed Loan Amount (₹)', '25,00,000')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildInputField('Interest Rate (%)', '11.50')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: _buildInputField('Loan Tenure (Months)', '60')),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                height: 46, // Match the approximate height of the input field
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: LoanDeskTheme.primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {},
                                  child: const Text(
                                    'Calculate',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        const Divider(height: 1, thickness: 1, color: Colors.black12),
                        const SizedBox(height: 32),
                        
                        // Output Grid First Row
                        Row(
                          children: [
                            Expanded(child: _buildMetricBox('EMI (₹)', '54,956')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildMetricBox('Total Interest (₹)', '8,97,360')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildMetricBox('Total Payment (₹)', '33,97,360')),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Output Grid Second Row
                        Row(
                          children: [
                            Expanded(child: _buildMetricBox('DSCR (After Loan)', '1.35')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildMetricBox('Repayment Capacity', 'Good', valueColor: const Color(0xFF2E7D32))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildMetricBox('Indicative Loan Range', '₹ 18L - ₹ 30L')),
                          ],
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Footer
                        const Center(
                          child: Text(
                            '(Indicative Only - Final decision as per bank policy)',
                            style: TextStyle(
                              color: LoanDeskTheme.primaryRed,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            NeoButton(
              text: 'Next: Document Checklist',
              color: LoanDeskTheme.primaryBlue,
              isFullWidth: true,
              onPressed: () {
                context.push('/loandesk/cases/document-checklist/$caseId');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: LoanDeskTheme.primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black12, width: 1.5),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: LoanDeskTheme.primaryBlack,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox(String label, String value, {Color valueColor = LoanDeskTheme.primaryBlack}) {
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
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
