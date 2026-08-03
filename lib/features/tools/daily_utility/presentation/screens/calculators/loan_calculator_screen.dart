import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../../providers/daily_utility_providers.dart';


class LoanCalculatorScreen extends ConsumerStatefulWidget {
  const LoanCalculatorScreen({super.key});

  @override
  ConsumerState<LoanCalculatorScreen> createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends ConsumerState<LoanCalculatorScreen> {

  List<Map<String, dynamic>> _history = [];
  static const String _historyKey = 'loan_history';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString(_historyKey);
    if (historyString != null) {
      final List<dynamic> decoded = jsonDecode(historyString);
      setState(() {
        _history = decoded.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _saveToHistory(String input, String result) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = {
      'input': input,
      'result': result,
      'calculatedOn': DateFormat('dd MMM yyyy HH:mm').format(DateTime.now()),
    };
    _history.insert(0, entry);
    if (_history.length > 10) _history = _history.sublist(0, 10);
    await prefs.setString(_historyKey, jsonEncode(_history));
    setState(() {});
  }

  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  final _yearsController = TextEditingController();

  double _emi = 0.0;
  double _totalInterest = 0.0;
  double _totalPayment = 0.0;
  bool _isLoading = false;

  Future<void> _calculate() async {
    double p = double.tryParse(_amountController.text) ?? 0.0;
    double r = double.tryParse(_rateController.text) ?? 0.0;
    double y = double.tryParse(_yearsController.text) ?? 0.0;

    if (p == 0 || r == 0 || y == 0) {
      setState(() {
        _emi = 0;
        _totalInterest = 0;
        _totalPayment = 0;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref.read(dailyUtilityServiceProvider).calculateLoan(
        principal: p,
        annualRate: r,
        tenureMonths: (y * 12).toInt(),
      );

      setState(() {
        _emi = (result['emi'] as num).toDouble();
        _totalPayment = (result['total_payment'] as num).toDouble();
        _totalInterest = (result['total_interest'] as num).toDouble();
        _isLoading = false;
      });
      _saveToHistory(
        '₹${_amountController.text}, ${_rateController.text}%, ${_yearsController.text} Yrs',
        'EMI: ₹${_emi.toStringAsFixed(2)}'
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to calculate Loan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Loan Calculator',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Instructions
            NeoCard(
              backgroundColor: const Color(0xFFE0FBFC), // Light Blue tint
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.black),
                      const SizedBox(width: 8),
                      Text('How to use', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "1. Enter the total loan amount.\n2. Enter the annual interest rate.\n3. Enter the tenure in years.\n4. Tap 'Calculate' to view your total payment.", style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            NeoCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputRow('Loan Amount (₹)', _amountController, 'e.g., 500000'),
                  const SizedBox(height: 16),
                  _buildInputRow('Interest Rate (%)', _rateController, 'e.g., 8.5'),
                  const SizedBox(height: 16),
                  _buildInputRow('Loan Tenure (Years)', _yearsController, 'e.g., 5'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_emi > 0)
              NeoCard(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly EMI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('₹${_emi.toStringAsFixed(0)}', style: AppTextStyles.heroTitle.copyWith(color: Colors.white, fontSize: 24)),
                      ],
                    ),
                    const Divider(color: Colors.white, thickness: 2, height: 32),
                    _buildResultRow('Total Interest', _totalInterest),
                    const SizedBox(height: 12),
                    _buildResultRow('Total Payment', _totalPayment),
                  ],
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
          ),
          onChanged: (_) => _calculate(),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

}