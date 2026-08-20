import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_card.dart';
import '../../widgets/neo_button.dart';

class FinancialAnalysisScreen extends StatefulWidget {
  final String caseId;

  const FinancialAnalysisScreen({
    super.key,
    required this.caseId,
  });

  @override
  State<FinancialAnalysisScreen> createState() => _FinancialAnalysisScreenState();
}

class _FinancialAnalysisScreenState extends State<FinancialAnalysisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          'Financial Analysis',
          style: TextStyle(
            color: LoanDeskTheme.primaryBlack,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
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
                '7. FINANCIAL ANALYSIS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            
            // TabBar and Content Container
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  border: Border(
                    left: BorderSide(color: LoanDeskTheme.primaryBlack, width: 1),
                    right: BorderSide(color: LoanDeskTheme.primaryBlack, width: 1),
                    bottom: BorderSide(color: LoanDeskTheme.primaryBlack, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    // Tab Bar
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: LoanDeskTheme.primaryBlue,
                      unselectedLabelColor: Colors.black54,
                      indicatorColor: LoanDeskTheme.primaryBlue,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Key Ratios'),
                        Tab(text: 'P&L Summary'),
                        Tab(text: 'Balance Sheet Summary'),
                      ],
                    ),
                    const Divider(height: 1, thickness: 1, color: Colors.black12),
                    
                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildKeyRatiosTab(),
                          const Center(child: Text('P&L Summary Placeholder', style: TextStyle(fontWeight: FontWeight.bold))),
                          const Center(child: Text('Balance Sheet Summary Placeholder', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRatiosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDataRow('Current Ratio', '1.48'),
                _buildDataRow('Quick Ratio', '0.98'),
                _buildDataRow('Debt Equity Ratio', '1.12'),
                _buildDataRow('Gross Profit %', '18.75%'),
                _buildDataRow('Net Profit %', '8.65%'),
                _buildDataRow('EBITDA %', '12.40%'),
                _buildDataRow('Interest Coverage Ratio', '2.35'),
                _buildDataRow('DSCR (Calculated)', '1.72', isLast: true),
                
                const Divider(height: 1, thickness: 1, color: Colors.black12),
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: const [
                      Text(
                        'Source:',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: LoanDeskTheme.primaryBlack,
                        ),
                      ),
                      SizedBox(width: 24),
                      Expanded(
                        child: Text(
                          'Extracted from uploaded P&L & Balance Sheet',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: LoanDeskTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          NeoButton(
            text: 'Next: Indicative Loan Calculator',
            color: LoanDeskTheme.primaryBlue,
            isFullWidth: true,
            onPressed: () {
              context.push('/loandesk/cases/loan-calculator/${widget.caseId}');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Colors.black12, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: LoanDeskTheme.primaryBlack,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: LoanDeskTheme.primaryBlack,
            ),
          ),
        ],
      ),
    );
  }
}
