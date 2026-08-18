import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_button.dart';
import '../../widgets/neo_text_field.dart';
import '../../providers/document_provider.dart';

class OcrReviewScreen extends ConsumerStatefulWidget {
  final String caseId;
  final String docId;
  final String docName;

  const OcrReviewScreen({
    super.key,
    required this.caseId,
    required this.docId,
    required this.docName,
  });

  @override
  ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  bool _isExtracting = true;
  
  // Mock extracted data
  final _nameController = TextEditingController(text: 'Rahul Sharma');
  final _panController = TextEditingController(text: 'ABCDE1234F');
  final _dobController = TextEditingController(text: '15/08/1985');

  @override
  void initState() {
    super.initState();
    // Simulate OCR delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isExtracting = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _panController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoanDeskTheme.background,
      appBar: AppBar(
        backgroundColor: LoanDeskTheme.primaryWhite,
        elevation: 0,
        title: Text(
          'Extract Data: ${widget.docName}',
          style: const TextStyle(
            color: LoanDeskTheme.primaryBlack,
            fontWeight: FontWeight.w900,
            fontSize: 18,
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
        child: _isExtracting
            ? _buildLoadingState()
            : _buildReviewForm(),
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
            'Running On-Device OCR...',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Extracting structured data from document.',
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mock Image Preview
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: LoanDeskTheme.primaryBlack, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Scanned Document Image',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Review Extracted Data',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please verify and correct any misread characters before saving.',
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          NeoTextField(
            label: 'Full Name',
            controller: _nameController,
          ),
          const SizedBox(height: 16),
          NeoTextField(
            label: 'PAN Number',
            controller: _panController,
          ),
          const SizedBox(height: 16),
          NeoTextField(
            label: 'Date of Birth',
            controller: _dobController,
          ),
          const SizedBox(height: 32),
          NeoButton(
            text: 'CONFIRM & SAVE',
            isFullWidth: true,
            color: LoanDeskTheme.primaryGreen,
            onPressed: () {
              // Update the document status in Riverpod
              ref.read(documentProvider(widget.caseId).notifier)
                 .updateDocumentStatus(widget.docId, 'Received', fileUrl: 'mock_path.pdf');
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Data extracted and saved successfully!', style: TextStyle(fontWeight: FontWeight.bold, color: LoanDeskTheme.primaryBlack)),
                  backgroundColor: LoanDeskTheme.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
                    side: const BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                ),
              );
              // Pop back to the workspace (pops OCR screen, then pops Scanner screen)
              context.pop();
              context.pop();
            },
          ),
        ],
      ),
    );
  }
}
