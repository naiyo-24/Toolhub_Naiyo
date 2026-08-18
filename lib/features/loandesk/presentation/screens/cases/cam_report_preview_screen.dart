import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_button.dart';

class CamReportPreviewScreen extends StatelessWidget {
  final String caseId;

  const CamReportPreviewScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoanDeskTheme.background,
      appBar: AppBar(
        backgroundColor: LoanDeskTheme.primaryWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: LoanDeskTheme.primaryBlack),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'CAM Report Preview',
          style: TextStyle(
            color: LoanDeskTheme.primaryBlack,
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: LoanDeskTheme.primaryBlack,
            height: LoanDeskTheme.borderWidth,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'CREDIT APPRAISAL MEMO (CAM)',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('1. APPLICANT DETAILS'),
                      _buildDetailRow('Case ID:', caseId),
                      _buildDetailRow('Applicant Name:', 'Rahul Sharma'),
                      _buildDetailRow('Loan Type:', 'Business Loan'),
                      _buildDetailRow('Requested Amount:', '₹25,00,000'),
                      
                      const SizedBox(height: 24),
                      _buildSectionTitle('2. VERIFICATION SUMMARY'),
                      _buildDetailRow('PAN Status:', 'Verified (NSDL)'),
                      _buildDetailRow('GST Status:', 'Verified (GSTN)'),
                      _buildDetailRow('CIBIL Score:', '750 (Good)'),
                      
                      const SizedBox(height: 24),
                      _buildSectionTitle('3. FINANCIAL ANALYSIS'),
                      _buildDetailRow('Monthly Revenue:', '₹8,20,000'),
                      _buildDetailRow('Net Margin:', '15%'),
                      _buildDetailRow('DSCR:', '1.8x'),
                      
                      const SizedBox(height: 32),
                      const Divider(thickness: 2),
                      const SizedBox(height: 16),
                      const Text(
                        'DECISION: RECOMMENDED FOR APPROVAL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('____________________'),
                              SizedBox(height: 4),
                              Text('Credit Officer Sign'),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('____________________'),
                              SizedBox(height: 4),
                              Text('Date'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: LoanDeskTheme.primaryWhite,
                border: Border(
                  top: BorderSide(
                    color: LoanDeskTheme.primaryBlack,
                    width: LoanDeskTheme.borderWidth,
                  ),
                ),
              ),
              child: NeoButton(
                text: 'DOWNLOAD PDF',
                isFullWidth: true,
                color: LoanDeskTheme.primaryBlue,
                textColor: LoanDeskTheme.primaryWhite,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading CAM Report PDF...')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
