import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_button.dart';

class DocumentChecklistScreen extends StatelessWidget {
  final String caseId;

  const DocumentChecklistScreen({
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
          'Checklist',
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
                      color: Color(0xFF0D1B2A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '9. DOCUMENT CHECKLIST',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Case ID : $caseId',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: LoanDeskTheme.primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(flex: 4, child: Text('Document', style: TextStyle(fontWeight: FontWeight.w900, color: LoanDeskTheme.primaryBlue, fontSize: 13))),
                                    Expanded(flex: 2, child: Text('Required', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: LoanDeskTheme.primaryBlue, fontSize: 13))),
                                    Expanded(flex: 2, child: Text('Received', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: LoanDeskTheme.primaryBlue, fontSize: 13))),
                                    Expanded(flex: 3, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: LoanDeskTheme.primaryBlue, fontSize: 13))),
                                  ],
                                ),
                              ),
                              
                              // Table Rows
                              _buildRow('PAN Card', true, true, 'Received'),
                              _buildRow('GST Certificate', true, true, 'Received'),
                              _buildRow('Udyam Certificate', true, true, 'Received'),
                              _buildRow('ITR (Latest)', true, true, 'Received'),
                              _buildRow('Bank Statement (6 Months)', true, true, 'Received'),
                              _buildRow('P&L Statement', true, false, 'Pending'),
                              _buildRow('Balance Sheet', true, false, 'Pending'),
                              _buildRow('Address Proof', true, true, 'Received'),
                              _buildRow('Photograph', false, true, 'Not Required'),
                              _buildRow('Other Document', 'As Required', false, 'Pending', isLast: true),
                              
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Footer
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Overall',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: LoanDeskTheme.primaryBlue,
                                ),
                              ),
                              Text(
                                '8 / 10',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: LoanDeskTheme.primaryBlack,
                                ),
                              ),
                              Text(
                                'Received',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: LoanDeskTheme.primaryBlack,
                                ),
                              ),
                            ],
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
              text: 'Next: Final Banker Report',
              color: LoanDeskTheme.primaryBlue,
              isFullWidth: true,
              onPressed: () {
                context.push('/loandesk/cases/final-report/$caseId');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String document, dynamic requiredVal, bool received, String status, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Colors.black12, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              document,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: LoanDeskTheme.primaryBlack),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildIconOrText(requiredVal),
          ),
          Expanded(
            flex: 2,
            child: _buildIconOrText(received),
          ),
          Expanded(
            flex: 3,
            child: _buildStatusBadge(status),
          ),
        ],
      ),
    );
  }

  Widget _buildIconOrText(dynamic value) {
    if (value is bool) {
      if (value) {
        return const Icon(Icons.check, color: Color(0xFF2E7D32), size: 18);
      } else {
        return const Icon(Icons.close, color: LoanDeskTheme.primaryRed, size: 18);
      }
    } else {
      return Text(
        value.toString(),
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: LoanDeskTheme.primaryBlack),
      );
    }
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'Not Required') {
      return Text(
        status,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: LoanDeskTheme.primaryBlack),
      );
    }

    Color bgColor;
    Color textColor;
    
    if (status == 'Received') {
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
    } else {
      bgColor = const Color(0xFFFFEBEE);
      textColor = LoanDeskTheme.primaryRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}
