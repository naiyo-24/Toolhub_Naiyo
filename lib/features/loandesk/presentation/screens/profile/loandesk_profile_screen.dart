import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_card.dart';
import '../../widgets/neo_button.dart';
import '../../providers/auth_provider.dart';

class LoanDeskProfileScreen extends ConsumerWidget {
  const LoanDeskProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: LoanDeskTheme.background,
      appBar: AppBar(
        backgroundColor: LoanDeskTheme.primaryWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: LoanDeskTheme.primaryBlack),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Banker Profile',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: LoanDeskTheme.primaryYellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: LoanDeskTheme.primaryBlack, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: LoanDeskTheme.primaryBlack,
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  backgroundImage: user?.profilePhoto != null ? NetworkImage(user!.profilePhoto!) : null,
                  child: user?.profilePhoto == null
                      ? Text(
                          (user?.fullName != null && user!.fullName.isNotEmpty) 
                              ? user.fullName.substring(0, 1).toUpperCase() 
                              : 'B',
                          style: const TextStyle(
                            color: LoanDeskTheme.primaryBlack,
                            fontWeight: FontWeight.w900,
                            fontSize: 48,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                (user?.fullName != null && user!.fullName.isNotEmpty) 
                    ? user.fullName 
                    : 'Banker Name',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: LoanDeskTheme.primaryBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (user?.email != null && user!.email.isNotEmpty) 
                    ? user.email 
                    : 'banker@loandesk.app',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              NeoCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.badge, 'Employee ID', user?.employeeId ?? 'N/A'),
                    const Divider(height: 32, thickness: 1, color: Colors.black12),
                    _buildInfoRow(Icons.account_balance, 'Organization', user?.orgName ?? 'N/A'),
                    const Divider(height: 32, thickness: 1, color: Colors.black12),
                    _buildInfoRow(Icons.location_on, 'Branch', '${user?.branchName ?? 'N/A'}, ${user?.city ?? 'N/A'}'),
                    const Divider(height: 32, thickness: 1, color: Colors.black12),
                    _buildInfoRow(Icons.work, 'Role', user?.loandeskRole ?? 'N/A'),
                    const Divider(height: 32, thickness: 1, color: Colors.black12),
                    _buildInfoRow(Icons.assignment_ind, 'Designation', user?.designation ?? 'N/A'),
                    const Divider(height: 32, thickness: 1, color: Colors.black12),
                    _buildInfoRow(Icons.phone, 'Mobile', user?.mobileNumber ?? 'N/A'),
                    const Divider(height: 32, thickness: 1, color: Colors.black12),
                    _buildInfoRow(Icons.history, 'Experience', '${user?.experienceYears ?? 0} Years'),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              NeoButton(
                text: 'SIGN OUT',
                isFullWidth: true,
                color: LoanDeskTheme.primaryPink,
                textColor: LoanDeskTheme.primaryBlack,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        backgroundColor: LoanDeskTheme.primaryWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
                          side: const BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
                        ),
                        title: const Text(
                          'Sign Out',
                          style: TextStyle(fontWeight: FontWeight.w900, color: LoanDeskTheme.primaryBlack),
                        ),
                        content: const Text(
                          'Are you sure you want to sign out?',
                          style: TextStyle(fontWeight: FontWeight.w600, color: LoanDeskTheme.primaryBlack),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('CANCEL', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w800)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              ref.read(authProvider.notifier).signOut();
                              context.go('/');
                            },
                            child: const Text('SIGN OUT', style: TextStyle(color: LoanDeskTheme.primaryRed, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: LoanDeskTheme.primaryBlack, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: LoanDeskTheme.primaryBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
