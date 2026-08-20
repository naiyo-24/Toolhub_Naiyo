import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_card.dart';
import '../../widgets/neo_button.dart';

class ComparisonSummaryScreen extends StatelessWidget {
  final String caseId;

  const ComparisonSummaryScreen({
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
          'Comparison',
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
            // Container with Header and Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LoanDeskTheme.primaryBlack, width: 1),
              ),
              child: Column(
                children: [
                  // Dark blue header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D1B2A), // Dark blue
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '5. COMPARISON SUMMARY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('Check', style: TextStyle(fontWeight: FontWeight.w900, color: LoanDeskTheme.primaryBlue, fontSize: 13))),
                        Expanded(flex: 3, child: Text('Source 1', style: TextStyle(fontWeight: FontWeight.w900, color: LoanDeskTheme.primaryBlue, fontSize: 13))),
                        Expanded(flex: 3, child: Text('Source 2', style: TextStyle(fontWeight: FontWeight.w900, color: LoanDeskTheme.primaryBlue, fontSize: 13))),
                        Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w900, color: LoanDeskTheme.primaryBlue, fontSize: 13))),
                        Expanded(flex: 2, child: Text('Variance', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: LoanDeskTheme.primaryBlue, fontSize: 13))),
                      ],
                    ),
                  ),
                  
                  // Table Rows
                  _buildRow('PAN', 'ABCDE1234F', '(From GSTIN)', 'Match', '-'),
                  _buildRow('GST vs Udyam', 'ABC TRADERS', 'ABC TRADERS', 'Match', '-'),
                  _buildRow('Name (All Docs)', 'ABC TRADERS', 'ABC TRADERS', 'Match', '-'),
                  _buildRow('Address (All Docs)', 'Match', 'Match', 'Match', '-'),
                  _buildRow('GST Turnover vs ITR', '₹ 82,40,000', '₹ 81,10,000', 'Good', '1.61%'),
                  _buildRow('GST Turnover vs Bank', '₹ 82,40,000', '₹ 79,80,000', 'Good', '3.16%'),
                  _buildRow('ITR vs Bank', '₹ 81,10,000', '₹ 79,80,000', 'Good', '1.60%'),
                  _buildRow('MSME Classification', 'Micro', 'Micro', 'Match', '-', isLast: true),
                  
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Overall Consistency',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: LoanDeskTheme.primaryBlack,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9), // Light green
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'GOOD',
                            style: TextStyle(
                              color: Color(0xFF2E7D32), // Dark green text
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: NeoButton(
                      text: 'Next: Bank Statement Analysis',
                      color: LoanDeskTheme.primaryBlue,
                      isFullWidth: true,
                      onPressed: () {
                        context.push('/loandesk/cases/bank-analysis/$caseId');
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String check, String source1, String source2, String status, String variance, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Colors.black12, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              check,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: LoanDeskTheme.primaryBlack),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              source1,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: LoanDeskTheme.primaryBlack),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              source2,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: LoanDeskTheme.primaryBlack),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildBadge(status),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              variance,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: LoanDeskTheme.primaryBlack),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Light green
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF2E7D32), // Dark green text
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}
