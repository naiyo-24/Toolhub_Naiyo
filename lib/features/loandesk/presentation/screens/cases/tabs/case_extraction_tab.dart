import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/loandesk_theme.dart';
import '../../../widgets/neo_card.dart';
import '../../../widgets/neo_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/ocr_provider.dart';
import '../../../../domain/entities/document_requirement.dart';
import '../../../../domain/entities/loan_case.dart';
import '../../reports/case_summary_pdf_screen.dart';

class CaseExtractionTab extends ConsumerStatefulWidget {
  final LoanCase loanCase;

  const CaseExtractionTab({
    super.key,
    required this.loanCase,
  });

  @override
  ConsumerState<CaseExtractionTab> createState() => _CaseExtractionTabState();
}

class _CaseExtractionTabState extends ConsumerState<CaseExtractionTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: LoanDeskTheme.primaryBlack,
                border: Border(
                  top: BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
                  left: BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
                  right: BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
                ),
              ),
              child: const Text(
                'EXTRACTED DATA PREVIEW',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
            
            // TabBar and Content Container
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: LoanDeskTheme.primaryWhite,
                  border: Border(
                    left: BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
                    right: BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
                    bottom: BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
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
                        Tab(text: 'GST Data'),
                        Tab(text: 'Udyam Data'),
                        Tab(text: 'ITR Data'),
                        Tab(text: 'Bank Data'),
                      ],
                    ),
                    const Divider(height: 1, thickness: 1, color: Colors.black12),
                    
                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildExtractionTab('GST Certificate', 0),
                          _buildExtractionTab('Udyam Certificate', 1),
                          _buildExtractionTab('ITR', 2),
                          _buildExtractionTab('Bank Statement', 3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  String _getDocNameForIndex(int index) {
    switch (index) {
      case 0: return 'GST Certificate';
      case 1: return 'Udyam Certificate';
      case 2: return 'ITR';
      case 3: return 'Bank Statement';
      default: return '';
    }
  }

  Widget _buildExtractionTab(String documentName, int tabIndex) {
    final docsState = ref.watch(documentProvider(widget.loanCase.id));
    final docs = docsState.valueOrNull ?? [];
    
    final doc = docs.firstWhere(
      (d) => d.name == documentName,
      orElse: () => DocumentRequirement(id: '', name: documentName, status: 'Pending'),
    );

    if (doc.status != 'Uploaded' || doc.fileUrl == null) {
      return Center(child: Text('$documentName not uploaded yet.', style: const TextStyle(fontWeight: FontWeight.bold)));
    }

    final ocrState = ref.watch(ocrProvider(doc.fileUrl!));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          if (ocrState is AsyncLoading)
            _buildExtractionLoader()
          else if (ocrState.value == null)
            NeoButton(
              text: 'Run AI Extraction',
              color: LoanDeskTheme.primaryGreen,
              isFullWidth: true,
              onPressed: () {
                ref.read(ocrProvider(doc.fileUrl!).notifier).extractData();
              },
            )
          else ...[

            if (ocrState.value!['structured_data'] != null)
              NeoCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius - LoanDeskTheme.borderWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        color: LoanDeskTheme.primaryYellow,
                        child: const Text('STRUCTURED DATA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                      _buildDataGrid(Map<String, dynamic>.from(ocrState.value!['structured_data'])),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: NeoButton(
                    text: 'Re-extract Data',
                    color: LoanDeskTheme.primaryGreen,
                    onPressed: () {
                      ref.read(ocrProvider(doc.fileUrl!).notifier).extractData();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: NeoButton(
                    text: tabIndex < 3 ? 'Next: ${_getTabName(tabIndex + 1)}' : 'Generate CAM Report',
                    color: LoanDeskTheme.primaryBlue,
                    onPressed: () {
                      if (tabIndex < 3) {
                        // Move to next tab
                        _tabController.animateTo(tabIndex + 1);
                        
                        // Try to auto-extract the next document if it's uploaded
                        final nextDocName = _getDocNameForIndex(tabIndex + 1);
                        final docs = docsState.valueOrNull ?? [];
                        final nextDoc = docs.firstWhere(
                          (d) => d.name == nextDocName,
                          orElse: () => DocumentRequirement(id: '', name: nextDocName, status: 'Pending'),
                        );
                        if (nextDoc.status == 'Uploaded' && nextDoc.fileUrl != null) {
                          // Trigger extraction if it hasn't been extracted yet
                          final nextOcrState = ref.read(ocrProvider(nextDoc.fileUrl!));
                          if (nextOcrState.value == null) {
                            ref.read(ocrProvider(nextDoc.fileUrl!).notifier).extractData();
                          }
                        }
                      } else {
                        // Generate PDF Report directly
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CaseSummaryPdfScreen(loanCase: widget.loanCase),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getTabName(int index) {
    switch (index) {
      case 0: return 'GST Data';
      case 1: return 'Udyam Data';
      case 2: return 'ITR Data';
      case 3: return 'Bank Data';
      default: return 'Analysis';
    }
  }

  Widget _buildExtractionLoader() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: LoanDeskTheme.primaryYellow,
          border: Border.all(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
          borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
          boxShadow: const [
            BoxShadow(
              color: LoanDeskTheme.primaryBlack,
              offset: Offset(LoanDeskTheme.shadowOffset, LoanDeskTheme.shadowOffset),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: LoanDeskTheme.primaryBlack,
              strokeWidth: 4,
            ),
            SizedBox(height: 24),
            Text(
              'EXTRACTING DATA...',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.5,
                color: LoanDeskTheme.primaryBlack,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while the AI analyzes the document.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataGrid(Map<String, dynamic> data) {
    final entries = data.entries.toList();
    final rows = <TableRow>[];
    
    for (int i = 0; i < entries.length; i += 2) {
      final leftEntry = entries[i];
      final rightEntry = i + 1 < entries.length ? entries[i + 1] : null;
      final isEvenRow = (i / 2).floor().isEven;
      
      rows.add(TableRow(
        decoration: BoxDecoration(
          color: isEvenRow ? LoanDeskTheme.primaryWhite : const Color(0xFFF4F6F8),
        ),
        children: [
          _buildTableCell(leftEntry.key, leftEntry.value.toString()),
          if (rightEntry != null)
            _buildTableCell(rightEntry.key, rightEntry.value.toString())
          else
            Container(),
        ],
      ));
    }
    
    return Table(
      border: const TableBorder(
        top: BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
        bottom: BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
        horizontalInside: BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
        verticalInside: BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
      ),
      columnWidths: const {
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: rows,
    );
  }

  Widget _buildTableCell(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              color: LoanDeskTheme.primaryBlue,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty || value.toLowerCase() == 'null' ? 'N/A' : value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: LoanDeskTheme.primaryBlack,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
