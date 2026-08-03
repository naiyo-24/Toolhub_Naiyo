import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/widgets/universal_tool_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';

class FinanceToolsScreen extends StatefulWidget {
  const FinanceToolsScreen({super.key});

  @override
  State<FinanceToolsScreen> createState() => _FinanceToolsScreenState();
}

class _FinanceToolsScreenState extends State<FinanceToolsScreen> {
  String _searchQuery = '';
  bool _showAllTools = false;
  
  final List<Map<String, dynamic>> tools = [
      {'title': 'EMI Calculator', 'subtitle': 'Calculate EMI', 'icon': Icons.calculate_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Calculate'},
      {'title': 'SIP Calculator', 'subtitle': 'Calculate returns', 'icon': Icons.trending_up_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Calculate'},
      {'title': 'Loan Calculator', 'subtitle': 'Calculate loan amounts', 'icon': Icons.account_balance_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Calculate'},
      {'title': 'Tax Calculator', 'subtitle': 'Calculate taxes', 'icon': Icons.receipt_long_rounded, 'color': AppColors.primaryRed, 'actionText': 'Calculate'},
      {'title': 'GST Calculator', 'subtitle': 'Calculate GST', 'icon': Icons.receipt_rounded, 'color': AppColors.primaryPink, 'actionText': 'Calculate'},
      {'title': 'Currency Converter', 'subtitle': 'Live exchange rates', 'icon': Icons.currency_exchange_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Convert'},
      {'title': 'Savings Planner', 'subtitle': 'Plan your savings', 'icon': Icons.savings_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Plan'},
      {'title': 'Budget Planner', 'subtitle': 'Plan your budget', 'icon': Icons.pie_chart_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Plan'},
      {'title': 'Expense Tracker', 'subtitle': 'Track your expenses', 'icon': Icons.account_balance_wallet_rounded, 'color': AppColors.primaryRed, 'actionText': 'Track'},
      {'title': 'Investment Calc', 'subtitle': 'Calculate investments', 'icon': Icons.show_chart_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Calculate'},
      {'title': 'Compound Interest', 'subtitle': 'Calculate interest', 'icon': Icons.functions_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Calculate'},
      {'title': 'Salary Calculator', 'subtitle': 'Calculate take-home pay', 'icon': Icons.payments_rounded, 'color': AppColors.primaryPink, 'actionText': 'Calculate'},
  ];

  void _showComingSoon(BuildContext context) {
    SnackbarUtils.showNeoSnackBar(context, message: 'This finance tool is coming soon!');
  }

  @override
  Widget build(BuildContext context) {
    var filteredTools = tools.where((tool) {
      final title = (tool['title'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query);
    }).toList();

    if (_searchQuery.isEmpty && !_showAllTools) {
      filteredTools = filteredTools.take(6).toList();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: filteredTools.length,
                      itemBuilder: (context, index) {
                        final tool = filteredTools[index];
                        return _buildUtilityCard(context, tool);
                      },
                    ),
                    if (_searchQuery.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showAllTools = !_showAllTools;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(4, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              _showAllTools ? 'View Less' : 'View More',
                              style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: NeoCard(
        backgroundColor: AppColors.primaryYellow,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        borderRadius: 12,
        shadowOffset: const Offset(4, 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 18),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Finance ',
                        style: AppTextStyles.heroTitle.copyWith(fontSize: 22, color: Colors.black),
                      ),
                      Text(
                        'Tools',
                        style: AppTextStyles.logoText.copyWith(fontSize: 22, color: Colors.black, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  Text(
                    'MANAGE YOUR MONEY',
                    style: AppTextStyles.caption.copyWith(fontSize: 9, letterSpacing: 2, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search finance tools...',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurface),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildUtilityCard(BuildContext context, Map<String, dynamic> tool) {
    final cardColor = tool['color'] as Color;

    return UniversalToolCard(
      title: tool['title'] as String,
      subtitle: tool['subtitle'] as String?,
      color: cardColor,
      icon: tool['icon'] as IconData,
      actionText: tool['actionText'] as String,
      onTap: () => _showComingSoon(context),
    );
  }
}
