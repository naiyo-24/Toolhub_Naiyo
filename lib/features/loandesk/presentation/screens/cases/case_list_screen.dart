import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_card.dart';
import '../../providers/loan_case_provider.dart';
import 'package:intl/intl.dart';

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
  String? _selectedStatus = 'All';
  String? _selectedLoanType = 'All';
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final casesState = ref.watch(loanCaseProvider);
    final notifier = ref.read(loanCaseProvider.notifier);
    
    // First, search by query
    var cases = notifier.searchCases(_searchQuery);
    
    // Then filter by status if not 'All'
    if (_selectedStatus != 'All' && _selectedStatus != null) {
      cases = cases.where((c) => c.status.toLowerCase() == _selectedStatus!.toLowerCase()).toList();
    }
    
    // Then filter by loan type if not 'All'
    if (_selectedLoanType != 'All' && _selectedLoanType != null) {
      cases = cases.where((c) => c.loanType.toLowerCase() == _selectedLoanType!.toLowerCase()).toList();
    }

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
          'Cases',
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
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildSearchBar(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _buildDropdown(
                      _selectedStatus ?? 'All',
                      ['All', 'Draft', 'Documents Pending', 'Verification', 'In Progress', 'Completed', 'Rejected'],
                      (val) {
                        setState(() {
                          _selectedStatus = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _buildDropdown(
                      _selectedLoanType ?? 'All',
                      ['All', 'Business Loan', 'MSME Loan', 'Personal Loan', 'Home Loan', 'Vehicle Loan'],
                      (val) {
                        setState(() {
                          _selectedLoanType = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: casesState.when(
                loading: () => const Center(child: CircularProgressIndicator(color: LoanDeskTheme.primaryBlack)),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (_) {
                  if (cases.isEmpty) {
                    return const Center(
                      child: Text('No cases found', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                    );
                  }
                  return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: cases.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final loanCase = cases[index];
                  String formattedDate = DateFormat('dd MMM yyyy').format(loanCase.applicationDate);
                  
                  return InkWell(
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
                                loanCase.caseNumber,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              _buildStatusBadge(loanCase.status),
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet, size: 16, color: Colors.black54),
                              const SizedBox(width: 4),
                              Text(
                                loanCase.loanType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.currency_rupee, size: 16, color: Colors.black54),
                              const SizedBox(width: 4),
                              Text(
                                _currencyFormat.format(loanCase.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                              const SizedBox(width: 6),
                              Text(
                                'Applied: $formattedDate',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
        ),
      ),
      floatingActionButton: widget.isTab ? null : FloatingActionButton(
        heroTag: 'case_list_fab',
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LoanDeskTheme.primaryBlack,
          width: LoanDeskTheme.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: LoanDeskTheme.primaryBlack,
            offset: Offset(2, 2),
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
          hintText: 'Search...',
          hintStyle: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w800),
          prefixIcon: Icon(Icons.search, color: LoanDeskTheme.primaryBlack, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: LoanDeskTheme.primaryWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
        boxShadow: const [
          BoxShadow(
            color: LoanDeskTheme.primaryBlack,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: LoanDeskTheme.primaryBlack),
          items: options.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: LoanDeskTheme.primaryBlack),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'completed') {
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
    } else if (lowerStatus.contains('pending')) {
      bgColor = const Color(0xFFFFEBEE);
      textColor = LoanDeskTheme.primaryRed;
    } else { // In Progress or other
      bgColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFF57C00); // Orange
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
          fontSize: 10,
        ),
      ),
    );
  }
}
