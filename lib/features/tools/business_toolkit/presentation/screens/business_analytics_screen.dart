import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../providers/business_provider.dart';

class BusinessAnalyticsScreen extends ConsumerStatefulWidget {
  const BusinessAnalyticsScreen({super.key});

  @override
  ConsumerState<BusinessAnalyticsScreen> createState() => _BusinessAnalyticsScreenState();
}

class _BusinessAnalyticsScreenState extends ConsumerState<BusinessAnalyticsScreen> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final service = ref.read(businessServiceProvider);
      final data = await service.getBusinessAnalytics();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Business Analytics', style: AppTextStyles.screenHeading),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.primaryRed, size: 64),
              const SizedBox(height: 16),
              Text('Failed to load data', style: AppTextStyles.heroTitle.copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text(_error, style: AppTextStyles.bodyText, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = '';
                  });
                  _fetchData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_data == null) {
      return const Center(child: Text('No data available'));
    }

    final double totalRevenue = (_data!['total_historical_revenue'] as num).toDouble();
    final double totalExpenses = (_data!['total_historical_expenses'] as num).toDouble();
    final double netProfit = (_data!['net_profit_margin'] as num).toDouble();
    final int salesTransactions = _data!['total_sales_transactions_recorded'] as int;
    final int expenseTransactions = _data!['total_expense_transactions_recorded'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatCard(
            title: 'Net Profit',
            value: '₹${netProfit.toStringAsFixed(2)}',
            icon: Icons.monetization_on_rounded,
            color: netProfit >= 0 ? AppColors.primaryGreen : AppColors.primaryRed,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Revenue',
                  value: '₹${totalRevenue.toStringAsFixed(2)}',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Expenses',
                  value: '₹${totalExpenses.toStringAsFixed(2)}',
                  icon: Icons.trending_down_rounded,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Sales Tx',
                  value: salesTransactions.toString(),
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Expense Tx',
                  value: expenseTransactions.toString(),
                  icon: Icons.receipt_rounded,
                  color: AppColors.primaryPink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          NeoCard(
            backgroundColor: AppColors.primaryYellow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.black),
                    const SizedBox(width: 8),
                    Text('Data Status', style: AppTextStyles.toolCardTitle.copyWith(color: Colors.black)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _data!['status'] as String,
                  style: AppTextStyles.bodyText.copyWith(color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return NeoCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.caption.copyWith(fontSize: 14, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTextStyles.heroTitle.copyWith(fontSize: 24, color: Colors.black),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
