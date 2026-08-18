import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_card.dart';

class DocumentVaultScreen extends StatelessWidget {
  final String caseId;

  const DocumentVaultScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> folders = [
      {'name': 'Identity', 'count': 2, 'icon': Icons.person},
      {'name': 'Address', 'count': 1, 'icon': Icons.home},
      {'name': 'Income', 'count': 0, 'icon': Icons.monetization_on},
      {'name': 'Banking', 'count': 3, 'icon': Icons.account_balance},
      {'name': 'Business', 'count': 2, 'icon': Icons.business},
      {'name': 'Tax', 'count': 0, 'icon': Icons.receipt_long},
      {'name': 'Other', 'count': 1, 'icon': Icons.folder},
    ];

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
          'Document Vault',
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
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            return GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening ${folder['name']} Folder...')),
                );
              },
              child: NeoCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      folder['icon'] as IconData,
                      size: 48,
                      color: LoanDeskTheme.primaryBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      folder['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${folder['count']} Files',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
