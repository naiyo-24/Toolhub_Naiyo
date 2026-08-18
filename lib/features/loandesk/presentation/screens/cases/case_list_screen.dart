import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_card.dart';
import '../../providers/loan_case_provider.dart';

class CaseListScreen extends ConsumerStatefulWidget {
  final bool isTab;
  final VoidCallback? onBackToDashboard;

  const CaseListScreen({
    super.key,
    this.isTab = false,
    this.onBackToDashboard,
  });

  @override
  ConsumerState<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends ConsumerState<CaseListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(loanCaseProvider.notifier);
    final cases = notifier.searchCases(_searchQuery);

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
          'Loan Cases',
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchBar(),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: cases.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final loanCase = cases[index];
                  return GestureDetector(
                    onTap: () {
                      context.push('/loandesk/cases/workspace/${loanCase.id}');
                    },
                    child: NeoCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loanCase.id,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: loanCase.status == 'Completed' 
                                    ? LoanDeskTheme.primaryGreen 
                                    : LoanDeskTheme.primaryYellow,
                                borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
                                border: Border.all(color: LoanDeskTheme.primaryBlack, width: 2),
                              ),
                              child: Text(
                                loanCase.status.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loanCase.customerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loanCase.loanType,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '₹${loanCase.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/loandesk/cases/create');
        },
        backgroundColor: LoanDeskTheme.primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
          side: const BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
        ),
        child: const Icon(Icons.add, color: LoanDeskTheme.primaryWhite),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: LoanDeskTheme.primaryWhite,
        borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
        border: Border.all(
          color: LoanDeskTheme.primaryBlack,
          width: LoanDeskTheme.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: LoanDeskTheme.primaryBlack,
            offset: Offset(LoanDeskTheme.shadowOffset, LoanDeskTheme.shadowOffset),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: const InputDecoration(
          hintText: 'Search by Customer or Case ID',
          prefixIcon: Icon(Icons.search, color: LoanDeskTheme.primaryBlack),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
