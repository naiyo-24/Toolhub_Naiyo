import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_button.dart';
import 'dart:math';

class FinalBankerReportScreen extends StatelessWidget {
  final String caseId;

  const FinalBankerReportScreen({
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
          'Final Report',
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
                      '10. FINAL BANKER REPORT (SAMPLE)',
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
                      children: [
                        // PDF Preview Container
                        Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black12, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Report Title
                              const Text(
                                'BUSINESS VERIFICATION & CREDIT ANALYSIS REPORT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: LoanDeskTheme.primaryBlack,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Case ID - $caseId',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Content Layout
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Column (List)
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildListItem('1. Customer Details'),
                                        _buildListItem('2. Document Summary'),
                                        _buildListItem('3. Credit Summary'),
                                        _buildListItem('4. Financial Overview'),
                                        _buildListItem('5. Financial Ratios'),
                                        _buildListItem('6. Compare Summary'),
                                        _buildListItem('7. Risk Indicators'),
                                        _buildListItem('8. Observations'),
                                        _buildListItem('9. Recommendation'),
                                      ],
                                    ),
                                  ),
                                  
                                  // Right Column (Data & Chart Mock)
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        // Mock Table
                                        _buildMockTableLine('Disbursing', 'Regularity'),
                                        _buildMockTableLine('Outsanding', '65,000'),
                                        const SizedBox(height: 8),
                                        _buildMockTableLine('Delinquency', 'None', color: const Color(0xFF2E7D32)),
                                        _buildMockTableLine('Repayment', 'Clear', color: const Color(0xFF2E7D32)),
                                        const SizedBox(height: 8),
                                        _buildMockTableLine('Total EMI', '45,000'),
                                        
                                        const SizedBox(height: 32),
                                        
                                        // Mock Chart
                                        SizedBox(
                                          height: 100,
                                          width: 100,
                                          child: CustomPaint(
                                            painter: _MockPieChartPainter(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Watermark / Footer
                              const Text(
                                'Generated by Tool Hub',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: LoanDeskTheme.primaryBlack,
                                ),
                              ),
                              const Text(
                                'Date: 2026-08-18\nStrictly Confidental',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
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
                                    'Download PDF',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                height: 48,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: LoanDeskTheme.primaryBlack,
                                    side: const BorderSide(color: Colors.black12, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () {},
                                  child: const Text(
                                    'Print Report',
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
                        
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            NeoButton(
              text: 'Finish Setup & Go to Case Workspace',
              color: LoanDeskTheme.primaryGreen,
              isFullWidth: true,
              onPressed: () {
                context.go('/loandesk/cases/workspace/$caseId');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: LoanDeskTheme.primaryBlack,
        ),
      ),
    );
  }
  
  Widget _buildMockTableLine(String left, String right, {Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: Colors.black87),
          ),
          Text(
            right,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}

class _MockPieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paintGreen = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;
      
    final paintOrange = Paint()
      ..color = const Color(0xFFFFA000)
      ..style = PaintingStyle.fill;

    // Draw orange slice (about 25%)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // Start angle (left)
      pi / 2, // Sweep angle (90 degrees)
      true,
      paintOrange,
    );
    
    // Draw green slice (about 75%)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi + pi / 2, // Start angle (bottom)
      3 * pi / 2, // Sweep angle (270 degrees)
      true,
      paintGreen,
    );
    
    // Draw inner white circle for donut hole
    final paintWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.4, paintWhite);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
