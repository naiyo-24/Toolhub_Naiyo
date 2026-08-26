import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_case_provider.dart';

class LoanDeskDashboardTab extends ConsumerWidget {
  final void Function(int)? onSwitchTab;

  const LoanDeskDashboardTab({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authProvider);
    final user = userState.user;
    final casesState = ref.watch(loanCaseProvider);
    final cases = casesState.valueOrNull ?? [];
    
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: LoanDeskTheme.primaryWhite,
            elevation: 0,
            pinned: true,
            toolbarHeight: 80,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/loandesk/profile'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: LoanDeskTheme.primaryYellow,
                      shape: BoxShape.circle,
                      border: Border.all(color: LoanDeskTheme.primaryBlack, width: 2),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      backgroundImage: user?.profilePhoto != null ? NetworkImage(user!.profilePhoto!) : null,
                      child: user?.profilePhoto == null
                          ? Text(
                              (user?.fullName != null && user!.fullName.isNotEmpty) 
                                  ? user.fullName.substring(0, 1).toUpperCase() 
                                  : 'B',
                              style: const TextStyle(color: LoanDeskTheme.primaryBlack, fontWeight: FontWeight.bold, fontSize: 20),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Good morning, ${user?.fullName.split(' ').first ?? 'Banker'} 👋',
                        style: const TextStyle(
                          color: LoanDeskTheme.primaryBlack,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'LoanDesk Workspace',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // actions removed
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: LoanDeskTheme.primaryBlack,
                height: LoanDeskTheme.borderWidth,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSearchBar(context),
                const SizedBox(height: 24),
                if (casesState.hasError)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.red.shade100,
                    child: Text('Error loading cases: ${casesState.error}', style: const TextStyle(color: Colors.red)),
                  ),
                _buildStatsGrid(context, cases),
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildRecentCases(context, cases),
                const SizedBox(height: 80), // Padding for FAB
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
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
        readOnly: true,
        onTap: () => context.push('/loandesk/search'),
        decoration: const InputDecoration(
          hintText: 'Search Customer / Case ID / PAN',
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

  Widget _buildStatsGrid(BuildContext context, List<dynamic> cases) {
    final activeCases = cases.where((c) => c.status != 'Completed' && c.status != 'Approved' && c.status != 'Rejected').length;
    final completedCases = cases.where((c) => c.status == 'Completed' || c.status == 'Approved' || c.status == 'Rejected').length;
    final pendingDocs = cases.where((c) => c.status.toString().contains('Pending') || c.status.toString().contains('DRAFT')).length;
    final underReview = cases.where((c) => c.status.toString().contains('Review') || c.status.toString().contains('Verification')).length;

    void navigateToCases() {
      if (onSwitchTab != null) {
        onSwitchTab!(2);
      } else {
        context.push('/loandesk/cases');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Active Cases',
                value: activeCases.toString(),
                color: LoanDeskTheme.primaryYellow,
                onTap: navigateToCases,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Pending Docs',
                value: pendingDocs.toString(),
                color: LoanDeskTheme.primaryPink,
                onTap: navigateToCases,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Under Review',
                value: underReview.toString(),
                color: LoanDeskTheme.primaryBlue,
                textColor: LoanDeskTheme.primaryWhite,
                onTap: navigateToCases,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Completed',
                value: completedCases.toString(),
                color: LoanDeskTheme.primaryGreen,
                onTap: navigateToCases,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.only(bottom: 8, right: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (onSwitchTab != null) {
                    onSwitchTab!(1);
                  } else {
                    context.push('/loandesk/customers');
                  }
                },
                child: const _ActionChip(title: 'Customers', icon: Icons.people_alt),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => context.push('/loandesk/cases/create'),
                child: const _ActionChip(title: 'New Case', icon: Icons.add_box),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  if (onSwitchTab != null) {
                    onSwitchTab!(3);
                  } else {
                    context.push('/loandesk/analysis/bank-statement');
                  }
                },
                child: const _ActionChip(title: 'Bank Statement', icon: Icons.account_balance),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => context.push('/tools/finance/calculator'),
                child: const _ActionChip(title: 'Loan Calculator', icon: Icons.calculate),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCases(BuildContext context, List<dynamic> cases) {
    final recentCases = cases.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Cases',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            TextButton(
              onPressed: () => context.push('/loandesk/cases'),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: LoanDeskTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        if (recentCases.isEmpty)
          const Text('No recent cases.', style: TextStyle(color: Colors.black54)),
        ...recentCases.map((loanCase) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onTap: () => context.push('/loandesk/cases/workspace/${loanCase.id}'),
                child: _CaseCard(
                  id: loanCase.caseNumber,
                  name: loanCase.customerName,
                  type: loanCase.loanType,
                  amount: '₹${loanCase.amount.toStringAsFixed(0)}',
                  status: loanCase.status,
                  statusColor: loanCase.status == 'Completed'
                      ? LoanDeskTheme.primaryGreen
                      : LoanDeskTheme.primaryYellow,
                ),
              ),
            )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    this.textColor = LoanDeskTheme.primaryBlack,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeoCard(
        backgroundColor: color,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 32,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ActionChip({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: LoanDeskTheme.primaryWhite,
        borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
        border: Border.all(
          color: LoanDeskTheme.primaryBlack,
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: LoanDeskTheme.primaryBlack,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final String id;
  final String name;
  final String type;
  final String amount;
  final String status;
  final Color statusColor;

  const _CaseCard({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                id,
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
                  border: Border.all(color: LoanDeskTheme.primaryBlack, width: 2),
                ),
                child: Text(
                  status,
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
            name,
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
                type,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
