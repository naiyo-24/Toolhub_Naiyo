import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../providers/loan_case_provider.dart';
import 'tabs/case_overview_tab.dart';
import 'tabs/case_documents_tab.dart';
import 'tabs/case_verification_tab.dart';
import 'tabs/case_analysis_tab.dart';
import 'tabs/case_timeline_tab.dart';

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

  @override
  Widget build(BuildContext context) {
    final loanCases = ref.watch(loanCaseProvider);
    final loanCase = loanCases.firstWhere(
      (c) => c.id == widget.caseId,
      orElse: () => loanCases.first,
    );

    return Scaffold(
      backgroundColor: LoanDeskTheme.background,
      appBar: AppBar(
        backgroundColor: LoanDeskTheme.primaryWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: LoanDeskTheme.primaryBlack),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loanCase.customerName,
              style: const TextStyle(
                color: LoanDeskTheme.primaryBlack,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              loanCase.id,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
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
                Tab(text: 'Analysis'),
                Tab(text: 'Timeline'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            CaseOverviewTab(loanCase: loanCase),
            CaseDocumentsTab(loanCase: loanCase),
            CaseVerificationTab(loanCase: loanCase),
            CaseAnalysisTab(loanCase: loanCase),
            CaseTimelineTab(loanCase: loanCase),
          ],
        ),
      ),
    );
  }
}
