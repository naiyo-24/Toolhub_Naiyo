import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_button.dart';
import '../../widgets/neo_card.dart';

class BankStatementAnalyzerScreen extends ConsumerStatefulWidget {
  final bool isTab;
  final VoidCallback? onBackToDashboard;

  const BankStatementAnalyzerScreen({
    super.key,
    this.isTab = false,
    this.onBackToDashboard,
  });

  @override
  ConsumerState<BankStatementAnalyzerScreen> createState() => _BankStatementAnalyzerScreenState();
}

class _BankStatementAnalyzerScreenState extends ConsumerState<BankStatementAnalyzerScreen> {
  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;

  void _runAnalysis() {
    setState(() {
      _isAnalyzing = true;
    });
    
    // Simulate API delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _hasAnalyzed = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoanDeskTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: LoanDeskTheme.primaryWhite,
        elevation: 0,
        leading: widget.isTab && widget.onBackToDashboard == null 
            ? null 
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: LoanDeskTheme.primaryBlack),
                onPressed: () {
                  if (widget.isTab && widget.onBackToDashboard != null) {
                    widget.onBackToDashboard!();
                  } else {
                    context.pop();
                  }
                },
              ),
        title: const Text(
          'Statement Analyzer',
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
        child: _isAnalyzing
            ? _buildLoadingState()
            : _hasAnalyzed
                ? _buildAnalysisResults()
                : _buildUploadState(),
      ),
    );
  }

  Widget _buildUploadState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.account_balance, size: 80, color: LoanDeskTheme.primaryBlue),
          const SizedBox(height: 24),
          const Text(
            'Upload Bank Statement',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a PDF statement to extract metrics like average balance, credits, debits, and EMI bounces.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 48),
          NeoCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.upload_file, size: 48, color: Colors.black54),
                const SizedBox(height: 16),
                const Text(
                  'Tap to select PDF file',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          NeoButton(
            text: 'MOCK UPLOAD & ANALYZE',
            color: LoanDeskTheme.primaryGreen,
            onPressed: _runAnalysis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: LoanDeskTheme.primaryBlue),
          SizedBox(height: 24),
          Text(
            'Parsing Transactions...',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Applying AI to categorize credits and debits.',
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysis Results',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'HDFC Bank • Account ending in 1234',
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Credits', '₹12,45,000', LoanDeskTheme.primaryGreen)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('Total Debits', '₹8,30,000', LoanDeskTheme.primaryPink)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Avg Balance', '₹2,10,000', LoanDeskTheme.primaryWhite)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('EMI Bounces', '0', LoanDeskTheme.primaryBlue, textColor: Colors.white)),
            ],
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Transaction Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          NeoCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow('Highest Balance', '₹4,50,000'),
                const Divider(color: LoanDeskTheme.primaryBlack, thickness: 2),
                _buildSummaryRow('Lowest Balance', '₹45,000'),
                const Divider(color: LoanDeskTheme.primaryBlack, thickness: 2),
                _buildSummaryRow('Cash Deposits', '₹1,20,000'),
                const Divider(color: LoanDeskTheme.primaryBlack, thickness: 2),
                _buildSummaryRow('Cash Withdrawals', '₹80,000'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          NeoButton(
            text: 'SAVE ANALYSIS TO CASE',
            isFullWidth: true,
            color: LoanDeskTheme.primaryYellow,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analysis saved!')),
              );
              context.pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, {Color textColor = LoanDeskTheme.primaryBlack}) {
    return NeoCard(
      backgroundColor: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor == Colors.white ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
