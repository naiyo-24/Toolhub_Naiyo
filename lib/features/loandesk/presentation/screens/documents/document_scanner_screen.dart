import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_button.dart';
import '../../providers/document_provider.dart';

class DocumentScannerScreen extends ConsumerStatefulWidget {
  final String caseId;
  final String docId;
  final String docName;

  const DocumentScannerScreen({
    super.key,
    required this.caseId,
    required this.docId,
    required this.docName,
  });

  @override
  ConsumerState<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends ConsumerState<DocumentScannerScreen> {
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for scanner feel
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Scan: ${widget.docName}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Mock camera viewfinder
                  Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: LoanDeskTheme.primaryYellow, width: 4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  if (_isScanning)
                    const Text(
                      'Position document within frame',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.all(32),
                      color: Colors.white,
                      child: const Center(
                        child: Text(
                          'Mock Captured Document\n(PDF/JPG)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: LoanDeskTheme.primaryWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isScanning)
                    NeoButton(
                      text: 'CAPTURE',
                      color: LoanDeskTheme.primaryBlue,
                      onPressed: () {
                        setState(() {
                          _isScanning = false;
                        });
                      },
                    )
                  else ...[
                    NeoButton(
                      text: 'RETAKE',
                      color: LoanDeskTheme.primaryWhite,
                      onPressed: () {
                        setState(() {
                          _isScanning = true;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    NeoButton(
                      text: 'SAVE & EXTRACT DATA',
                      color: LoanDeskTheme.primaryGreen,
                      onPressed: () {
                        context.push('/loandesk/scanner/ocr', extra: {
                          'caseId': widget.caseId,
                          'docId': widget.docId,
                          'docName': widget.docName,
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
