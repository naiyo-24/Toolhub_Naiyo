import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/widgets/universal_tool_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:tool_hub/core/ads/banner_ad_widget.dart';

class DailyUtilityScreen extends StatefulWidget {
  const DailyUtilityScreen({super.key});

  @override
  State<DailyUtilityScreen> createState() => _DailyUtilityScreenState();
}

class _DailyUtilityScreenState extends State<DailyUtilityScreen> {
  String _searchQuery = '';
  bool _showAllTools = false;
  
  final List<Map<String, dynamic>> tools = [
      {'title': 'QR Code Generator', 'subtitle': 'Create custom QR codes', 'icon': Icons.qr_code_2_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Generate'},
      {'title': 'QR Code Scanner', 'subtitle': 'Scan QR codes instantly', 'icon': Icons.qr_code_scanner_rounded, 'color': AppColors.primaryPink, 'actionText': 'Scan Now'},
      {'title': 'Age Calculator', 'subtitle': 'Calculate exact age', 'icon': Icons.cake_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Calculate'},
      {'title': 'EMI Calculator', 'subtitle': 'Calculate loan EMIs', 'icon': Icons.calculate_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Calculate'},
      {'title': 'GST Calculator', 'subtitle': 'Calculate GST amounts', 'icon': Icons.receipt_long_rounded, 'color': AppColors.primaryPink, 'actionText': 'Calculate'},
      {'title': 'SIP Calculator', 'subtitle': 'Calculate SIP returns', 'icon': Icons.trending_up_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Calculate'},
      {'title': 'Loan Calculator', 'subtitle': 'Plan your loans', 'icon': Icons.account_balance_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Calculate'},
      {'title': 'BMI Calculator', 'subtitle': 'Check your BMI', 'icon': Icons.monitor_weight_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Calculate'},
      {'title': 'Percentage Calc', 'subtitle': 'Quick percentage math', 'icon': Icons.percent_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Calculate'},
      {'title': 'Discount Calc', 'subtitle': 'Calculate discount prices', 'icon': Icons.local_offer_rounded, 'color': AppColors.primaryPink, 'actionText': 'Calculate'},
      {'title': 'Unit Converter', 'subtitle': 'Convert units easily', 'icon': Icons.swap_horiz_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Convert'},
      {'title': 'Currency Converter', 'subtitle': 'Live exchange rates', 'icon': Icons.currency_exchange_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Convert'},
      {'title': 'Scientific Calc', 'subtitle': 'Advanced mathematics', 'icon': Icons.science_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Calculate'},
      {'title': 'Stopwatch', 'subtitle': 'Track time precisely', 'icon': Icons.timer_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Start'},
      {'title': 'Timer', 'subtitle': 'Countdown timer', 'icon': Icons.hourglass_bottom_rounded, 'color': AppColors.primaryPink, 'actionText': 'Start'},
      {'title': 'World Clock', 'subtitle': 'Global timezones', 'icon': Icons.language_rounded, 'color': AppColors.primaryYellow, 'actionText': 'View'},
      {'title': 'Calendar', 'subtitle': 'View dates & events', 'icon': Icons.calendar_month_rounded, 'color': AppColors.primaryGreen, 'actionText': 'View'},
      {'title': 'Password Gen', 'subtitle': 'Create secure passwords', 'icon': Icons.password_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Generate'},
      {'title': 'Password Check', 'subtitle': 'Test password strength', 'icon': Icons.security_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Check'},
      {'title': 'Text Counter', 'subtitle': 'Count words & characters', 'icon': Icons.text_fields_rounded, 'color': AppColors.primaryPink, 'actionText': 'Count'},
      {'title': 'Case Converter', 'subtitle': 'Convert text cases', 'icon': Icons.text_format_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Convert'},
      {'title': 'Bin ↔ Dec Converter', 'subtitle': 'Number base conversion', 'icon': Icons.numbers_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Convert'},
  ];

  void _showComingSoon(BuildContext context) {
    SnackbarUtils.showNeoSnackBar(context, message: 'This tool is coming soon!');
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
                        return _buildUtilityCard(
                          context, 
                          tool,
                          onTap: () {
                            if (tool['title'] == 'EMI Calculator') {
                              context.push('/emi-calculator');
                            } else if (tool['title'] == 'GST Calculator') {
                              context.push('/gst-calculator');
                            } else if (tool['title'] == 'SIP Calculator') {
                              context.push('/sip-calculator');
                            } else if (tool['title'] == 'Loan Calculator') {
                              context.push('/loan-calculator');
                            } else if (tool['title'] == 'Percentage Calc') {
                              context.push('/percentage-calculator');
                            } else if (tool['title'] == 'Discount Calc') {
                              context.push('/discount-calculator');
                            } else if (tool['title'] == 'Scientific Calc') {
                              context.push('/scientific-calculator');
                            } else if (tool['title'] == 'Age Calculator') {
                              context.push('/age-calculator');
                            } else if (tool['title'] == 'BMI Calculator') {
                              context.push('/bmi-calculator');
                            } else if (tool['title'] == 'Unit Converter') {
                              context.push('/unit-converter');
                            } else if (tool['title'] == 'Currency Converter') {
                              context.push('/currency-converter');
                            } else if (tool['title'] == 'Case Converter') {
                              context.push('/case-converter');
                            } else if (tool['title'] == 'Bin ↔ Dec Converter') {
                              context.push('/base-converter');
                            } else if (tool['title'] == 'Text Counter') {
                              context.push('/text-counter');
                            } else if (tool['title'] == 'Stopwatch') {
                              context.push('/stopwatch');
                            } else if (tool['title'] == 'Timer') {
                              context.push('/timer');
                            } else if (tool['title'] == 'World Clock') {
                              context.push('/world-clock');
                            } else if (tool['title'] == 'Calendar') {
                              context.push('/calendar');
                            } else if (tool['title'] == 'Password Gen') {
                              context.push('/password-generator');
                            } else if (tool['title'] == 'Password Check') {
                              context.push('/password-checker');
                            } else if (tool['title'] == 'QR Code Generator') {
                              context.push('/qr-generator');
                            } else if (tool['title'] == 'QR Code Scanner') {
                              context.push('/qr-scanner');
                            } else {
                              _showComingSoon(context);
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
                  
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: BannerAdWidget(),
                    ),
                    const SizedBox(height: 40),
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
                        'DAILY ',
                        style: AppTextStyles.heroTitle.copyWith(fontSize: 22, color: Colors.black),
                      ),
                      Text(
                        'Utility',
                        style: AppTextStyles.logoText.copyWith(fontSize: 22, color: Colors.black, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  Text(
                    'TOOLS IN ONE PLACE',
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
            hintText: 'Search tools...',
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

  Widget _buildUtilityCard(BuildContext context, Map<String, dynamic> tool, {VoidCallback? onTap}) {
    final cardColor = tool['color'] as Color;

    return UniversalToolCard(
      title: tool['title'] as String,
      subtitle: tool['subtitle'] as String?,
      color: cardColor,
      icon: tool['icon'] as IconData,
      actionText: tool['actionText'] as String,
      onTap: onTap ?? () => _showComingSoon(context),
    );
  }
}
