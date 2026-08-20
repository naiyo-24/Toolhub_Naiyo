import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../dashboard/loandesk_dashboard_tab.dart';
import '../customers/customer_list_screen.dart';
import '../cases/case_list_screen.dart';
import '../analysis/bank_statement_analyzer_screen.dart';

class LoanDeskMainScreen extends ConsumerStatefulWidget {
  const LoanDeskMainScreen({super.key});

  @override
  ConsumerState<LoanDeskMainScreen> createState() => _LoanDeskMainScreenState();
}

class _LoanDeskMainScreenState extends ConsumerState<LoanDeskMainScreen> {
  int _currentIndex = 0;

  void _backToDashboard() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      LoanDeskDashboardTab(
        onSwitchTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      CustomerListScreen(
        isTab: true,
        onBackToDashboard: _backToDashboard,
      ),
      CaseListScreen(
        isTab: true,
        onBackToDashboard: _backToDashboard,
      ),
      BankStatementAnalyzerScreen(
        isTab: true,
        onBackToDashboard: _backToDashboard,
      ),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _backToDashboard();
      },
      child: Scaffold(
        backgroundColor: LoanDeskTheme.background,
        body: tabs[_currentIndex],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: LoanDeskTheme.primaryBlack,
                width: LoanDeskTheme.borderWidth,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: LoanDeskTheme.primaryWhite,
            selectedItemColor: LoanDeskTheme.primaryBlue,
            unselectedItemColor: LoanDeskTheme.primaryBlack.withOpacity(0.6),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Customers',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_shared),
                label: 'Cases',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Analysis',
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'main_fab',
          backgroundColor: LoanDeskTheme.primaryBlue,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
            borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
          ),
          onPressed: () => context.push('/loandesk/cases/create'),
          icon: const Icon(Icons.add, color: LoanDeskTheme.primaryWhite),
          label: const Text(
            'New Case',
            style: TextStyle(color: LoanDeskTheme.primaryWhite, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
