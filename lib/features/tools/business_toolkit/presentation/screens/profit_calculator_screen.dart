import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/widgets/neo_text_field.dart';
import '../providers/business_provider.dart';

class ProfitCalculatorScreen extends ConsumerStatefulWidget {
  const ProfitCalculatorScreen({super.key});

  @override
  ConsumerState<ProfitCalculatorScreen> createState() => _ProfitCalculatorScreenState();
}

class _ProfitCalculatorScreenState extends ConsumerState<ProfitCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _revenueController = TextEditingController();
  final _cogsController = TextEditingController();
  final _expensesController = TextEditingController();
  final _taxesController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _revenueController.dispose();
    _cogsController.dispose();
    _expensesController.dispose();
    _taxesController.dispose();
    super.dispose();
  }

  void _calculate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final service = ref.read(businessServiceProvider);
      final result = await service.calculateProfit(
        totalRevenue: double.parse(_revenueController.text),
        cogs: double.parse(_cogsController.text),
        operatingExpenses: double.parse(_expensesController.text),
        taxesPaid: _taxesController.text.isNotEmpty ? double.parse(_taxesController.text) : 0,
      );

      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Profit Calculator', style: AppTextStyles.screenHeading),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: NeoCard(
                backgroundColor: Colors.white,
                child: Column(
                  children: [
                    NeoTextField(
                      controller: _revenueController,
                      label: 'Total Revenue',
                      hint: 'e.g. 50000',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    NeoTextField(
                      controller: _cogsController,
                      label: 'Cost of Goods Sold (COGS)',
                      hint: 'e.g. 20000',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    NeoTextField(
                      controller: _expensesController,
                      label: 'Operating Expenses',
                      hint: 'e.g. 10000',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    NeoTextField(
                      controller: _taxesController,
                      label: 'Taxes Paid (Optional)',
                      hint: 'e.g. 5000',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.black, width: 2),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text('Calculate Profit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final status = _result!['status'] as String;
    final isProfit = status == 'Profitable';

    return NeoCard(
      backgroundColor: isProfit ? AppColors.primaryGreen : AppColors.primaryRed,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                status.toUpperCase(),
                style: AppTextStyles.heroTitle.copyWith(color: Colors.white, fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildResultRow('Gross Profit', '₹${_result!['gross_profit']}'),
          _buildResultRow('Gross Margin', '${_result!['gross_margin_percentage']}%'),
          const Divider(color: Colors.white54, height: 32),
          _buildResultRow('Net Profit', '₹${_result!['net_profit']}', isBold: true),
          _buildResultRow('Net Margin', '${_result!['net_margin_percentage']}%', isBold: true),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyText.copyWith(
              color: Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 16,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyText.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isBold ? 20 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
