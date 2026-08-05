import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/widgets/universal_tool_card.dart';

class FinanceToolsScreen extends StatefulWidget {
  const FinanceToolsScreen({super.key});

  static final List<Map<String, dynamic>> tools = [
      {'title': 'EMI Calculator', 'subtitle': 'Calculate loan EMI', 'icon': Icons.calculate_rounded, 'color': AppColors.primaryPink, 'actionText': 'Calculate', 'endpoint': '/emi-calculator', 'config': [
        {'key': 'principal', 'label': 'Loan Amount', 'icon': Icons.attach_money},
        {'key': 'annual_interest_rate', 'label': 'Annual Interest Rate (%)', 'icon': Icons.percent},
        {'key': 'tenure_months', 'label': 'Tenure (Months)', 'icon': Icons.date_range}
      ]},
      {'title': 'SIP Calculator', 'subtitle': 'Mutual Fund Returns', 'icon': Icons.trending_up_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Calculate', 'endpoint': '/sip-calculator', 'config': [
        {'key': 'monthly_investment', 'label': 'Monthly Investment', 'icon': Icons.savings},
        {'key': 'expected_annual_return', 'label': 'Expected Return (%)', 'icon': Icons.percent},
        {'key': 'time_period_years', 'label': 'Time Period (Years)', 'icon': Icons.timelapse}
      ]},
      {'title': 'Loan Calculator', 'subtitle': 'Detailed Loan Plan', 'icon': Icons.account_balance_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Calculate', 'endpoint': '/loan-calculator', 'config': [
        {'key': 'principal', 'label': 'Loan Amount', 'icon': Icons.account_balance_wallet},
        {'key': 'annual_interest_rate', 'label': 'Interest Rate (%)', 'icon': Icons.percent},
        {'key': 'tenure_months', 'label': 'Tenure (Months)', 'icon': Icons.date_range}
      ]},
      {'title': 'Tax Calculator', 'subtitle': 'Income Tax Plan', 'icon': Icons.receipt_long_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Calculate', 'endpoint': '/tax-calculator', 'config': [
        {'key': 'annual_income', 'label': 'Annual Income', 'icon': Icons.monetization_on}
      ]},
      {'title': 'GST Calculator', 'subtitle': 'Goods & Services Tax', 'icon': Icons.shopping_cart_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Calculate', 'endpoint': '/gst-calculator', 'config': [
        {'key': 'amount', 'label': 'Base Amount', 'icon': Icons.price_change},
        {'key': 'gst_rate', 'label': 'GST Rate (%)', 'icon': Icons.percent},
        {'key': 'is_inclusive', 'label': 'Is GST Inclusive?', 'icon': Icons.check_box, 'type': 'checkbox'}
      ]},
      {'title': 'Currency Converter', 'subtitle': 'Exchange Rates', 'icon': Icons.currency_exchange_rounded, 'color': AppColors.primaryRed, 'actionText': 'Convert', 'endpoint': '/currency-converter', 'config': [
        {'key': 'amount', 'label': 'Amount', 'icon': Icons.money},
        {'key': 'from_currency', 'label': 'From Currency', 'icon': Icons.language, 'type': 'dropdown', 'options': ['USD', 'EUR', 'GBP', 'INR', 'AUD', 'CAD', 'SGD', 'CHF', 'MYR', 'JPY', 'CNY', 'AED']},
        {'key': 'to_currency', 'label': 'To Currency', 'icon': Icons.language, 'type': 'dropdown', 'options': ['USD', 'EUR', 'GBP', 'INR', 'AUD', 'CAD', 'SGD', 'CHF', 'MYR', 'JPY', 'CNY', 'AED']}
      ]},
      {'title': 'Savings Planner', 'subtitle': 'Plan your goals', 'icon': Icons.savings_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Plan', 'endpoint': '/savings-planner', 'config': [
        {'key': 'goal_amount', 'label': 'Target Goal Amount', 'icon': Icons.flag},
        {'key': 'expected_annual_return', 'label': 'Expected Return (%)', 'icon': Icons.percent},
        {'key': 'time_period_years', 'label': 'Time (Years)', 'icon': Icons.timelapse}
      ]},
      {'title': 'Budget Planner', 'subtitle': '50/30/20 Rule', 'icon': Icons.pie_chart_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Plan', 'endpoint': '/budget-planner', 'config': [
        {'key': 'monthly_income', 'label': 'Monthly Income', 'icon': Icons.account_balance_wallet},
        {'key': 'needs_percentage', 'label': 'Needs % (default 50)', 'icon': Icons.home},
        {'key': 'wants_percentage', 'label': 'Wants % (default 30)', 'icon': Icons.shopping_bag},
        {'key': 'savings_percentage', 'label': 'Savings % (default 20)', 'icon': Icons.savings}
      ]},
      {'title': 'Expense Tracker', 'subtitle': 'Track your spending', 'icon': Icons.receipt_rounded, 'color': AppColors.primaryPink, 'actionText': 'Track', 'endpoint': '/expensetracker', 'isExpenseTracker': true},
      {'title': 'Investment Calc', 'subtitle': 'Lumpsum Returns', 'icon': Icons.show_chart_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Calculate', 'endpoint': '/investment-calculator', 'config': [
        {'key': 'lumpsum_amount', 'label': 'Lumpsum Amount', 'icon': Icons.money},
        {'key': 'expected_annual_return', 'label': 'Expected Return (%)', 'icon': Icons.percent},
        {'key': 'time_period_years', 'label': 'Time Period (Years)', 'icon': Icons.timelapse}
      ]},
      {'title': 'Compound Interest', 'subtitle': 'Power of Compounding', 'icon': Icons.functions_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Calculate', 'endpoint': '/compound-interest', 'config': [
        {'key': 'principal', 'label': 'Principal Amount', 'icon': Icons.account_balance_wallet},
        {'key': 'annual_interest_rate', 'label': 'Interest Rate (%)', 'icon': Icons.percent},
        {'key': 'time_period_years', 'label': 'Time Period (Years)', 'icon': Icons.timelapse},
        {'key': 'compound_frequency', 'label': 'Compound Frequency (e.g. 12)', 'icon': Icons.repeat}
      ]},
      {'title': 'Salary Calculator', 'subtitle': 'In-hand salary breakdown', 'icon': Icons.payments_rounded, 'color': AppColors.primaryRed, 'actionText': 'Calculate', 'endpoint': '/salary-calculator', 'config': [
        {'key': 'ctc', 'label': 'Annual CTC', 'icon': Icons.work},
        {'key': 'basic_percentage', 'label': 'Basic % of CTC (default 50)', 'icon': Icons.percent},
        {'key': 'hra_percentage', 'label': 'HRA % of Basic (default 50)', 'icon': Icons.percent},
        {'key': 'standard_deduction', 'label': 'Standard Deduction (default 50k)', 'icon': Icons.money_off}
      ]},
  ];

  @override
  State<FinanceToolsScreen> createState() => _FinanceToolsScreenState();
}

class _FinanceToolsScreenState extends State<FinanceToolsScreen> {
  String _searchQuery = '';
  bool _showAllTools = false;

  @override
  Widget build(BuildContext context) {
    var filteredTools = FinanceToolsScreen.tools.where((tool) {
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
                        return UniversalToolCard(
                          title: tool['title'] as String,
                          subtitle: tool['subtitle'] as String?,
                          color: tool['color'] as Color,
                          icon: tool['icon'] as IconData,
                          actionText: tool['actionText'] as String,
                          onTap: () {
                            if (tool['isExpenseTracker'] == true) {
                              context.push('/finance-tools/expense-tracker', extra: tool);
                            } else {
                              context.push('/finance-tools/calculator', extra: tool);
                            }
                          },
                        );
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
                                )
                              ],
                            ),
                            child: Text(
                              _showAllTools ? 'View Less' : 'View All Tools',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryPink,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                onPressed: () => context.pop(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Finance ',
                          style: AppTextStyles.heroTitle.copyWith(fontSize: 22, color: Colors.black),
                        ),
                        TextSpan(
                          text: 'Tools',
                          style: AppTextStyles.logoText.copyWith(fontSize: 22, color: Colors.black, fontStyle: FontStyle.italic, fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SMART FINANCIAL CALCULATORS',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyText.copyWith(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48), // To balance the back button and center the text
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: NeoCard(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: const InputDecoration(
            hintText: 'Search finance tools...',
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
