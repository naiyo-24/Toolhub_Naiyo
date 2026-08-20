import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/api/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../providers/loan_case_provider.dart';
import 'tabs/case_overview_tab.dart';
import 'tabs/case_documents_tab.dart';
import 'tabs/case_verification_tab.dart';
import 'tabs/case_analysis_tab.dart';
import 'tabs/case_extraction_tab.dart';

import 'tabs/case_verification_tab.dart';

class CaseWorkspaceScreen extends ConsumerStatefulWidget {
  final String caseId;
  const CaseWorkspaceScreen({super.key, required this.caseId});

  @override
  ConsumerState<CaseWorkspaceScreen> createState() => _CaseWorkspaceScreenState();
}

class _CaseWorkspaceScreenState extends ConsumerState<CaseWorkspaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  Future<void> _downloadAndOpenReport(BuildContext context, String caseId, String caseNumber) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF Report...')));
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/Case_Report_$caseNumber.pdf';
      
      final dio = Dio();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      
      await dio.download(
        '${ApiConfig.loanDeskBaseUrl}/cases/$caseId/download-report',
        filePath,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report downloaded successfully!')));
      await OpenFilex.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download report: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {

    final loanCasesState = ref.watch(loanCaseProvider);
    final loanCases = loanCasesState.value ?? [];

    if (loanCasesState.isLoading || loanCases.isEmpty) {
      return const Scaffold(
        backgroundColor: LoanDeskTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final loanCase = loanCases.firstWhere(
      (c) => c.id == widget.caseId,
      orElse: () => loanCases.first,
    );

    return Scaffold(
      backgroundColor: LoanDeskTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              color: LoanDeskTheme.primaryWhite,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: LoanDeskTheme.primaryBlack),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loanCase.customerName,
                          style: const TextStyle(
                            color: LoanDeskTheme.primaryBlack,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          loanCase.caseNumber,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: LoanDeskTheme.primaryBlue),
                    tooltip: "Download PDF Report",
                    onPressed: () => _downloadAndOpenReport(context, loanCase.id.toString(), loanCase.caseNumber),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
                  bottom: BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
                ),
                color: LoanDeskTheme.primaryWhite,
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                labelColor: LoanDeskTheme.primaryBlack,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
                indicatorColor: LoanDeskTheme.primaryBlue,
                indicatorWeight: 4,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Documents'),
                  Tab(text: 'Verification'),
                  Tab(text: 'Extraction'),
                  Tab(text: 'Analysis'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  CaseOverviewTab(loanCase: loanCase),
                  CaseDocumentsTab(loanCase: loanCase),
                  CaseVerificationTab(loanCase: loanCase),
                  CaseExtractionTab(loanCase: loanCase),
                  CaseAnalysisTab(loanCase: loanCase),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
