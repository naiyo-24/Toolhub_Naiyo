import 'package:flutter/material.dart';
import '../../../../domain/entities/loan_case.dart';
import '../../../theme/loandesk_theme.dart';
import '../../../widgets/neo_card.dart';
import '../reports/case_summary_pdf_screen.dart';

class CaseAnalysisTab extends StatelessWidget {
  final LoanCase loanCase;

  const CaseAnalysisTab({super.key, required this.loanCase});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PDF Generation Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CaseSummaryPdfScreen(loanCase: loanCase),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text('GENERATE CAM REPORT (PDF)', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: LoanDeskTheme.primaryBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius - LoanDeskTheme.borderWidth),
                ),
                elevation: LoanDeskTheme.shadowOffset,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Financial Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NeoCard(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: LoanDeskTheme.primaryGreen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Monthly Revenue',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '₹8,20,000',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeoCard(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: LoanDeskTheme.primaryPink,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Monthly Expenses',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '₹5,10,000',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NeoCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: LoanDeskTheme.primaryYellow,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Net Cash Flow',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹3,10,000/mo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Key Financial Ratios',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildRatioCard('Current Ratio', '1.5x', 'Healthy (>1.2)'),
              _buildRatioCard('Debt/Equity', '2.1x', 'High (>1.5)'),
              _buildRatioCard('Net Margin', '15%', 'Good (>10%)'),
              _buildRatioCard('DSCR', '1.8x', 'Excellent (>1.5)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatioCard(String title, String value, String subtitle) {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: LoanDeskTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
