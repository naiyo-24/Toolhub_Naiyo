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


class SipCalculatorScreen extends ConsumerStatefulWidget {
  const SipCalculatorScreen({super.key});

  @override
  ConsumerState<SipCalculatorScreen> createState() => _SipCalculatorScreenState();
}

class _SipCalculatorScreenState extends ConsumerState<SipCalculatorScreen> {

  List<Map<String, dynamic>> _history = [];
  static const String _historyKey = 'sip_history';

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

  double _investedAmount = 0.0;
  double _estReturns = 0.0;
  double _totalValue = 0.0;
  bool _isLoading = false;

  Future<void> _calculate() async {
    double p = double.tryParse(_amountController.text) ?? 0.0;
    double r = double.tryParse(_rateController.text) ?? 0.0;
    int n = int.tryParse(_yearsController.text) ?? 0;

    if (p == 0 || r == 0 || n == 0) {
      setState(() {
        _investedAmount = 0;
        _estReturns = 0;
        _totalValue = 0;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref.read(dailyUtilityServiceProvider).calculateSip(
        monthlyInvestment: p,
        expectedAnnualReturn: r,
        tenureYears: n,
      );

      setState(() {
        _investedAmount = (result['invested_amount'] as num).toDouble();
        _totalValue = (result['total_value'] as num).toDouble();
        _estReturns = (result['estimated_returns'] as num).toDouble();
        _isLoading = false;
      });
      _saveToHistory(
        '₹${_amountController.text}/mo, ${_rateController.text}%, ${_yearsController.text} Yrs',
        'Total: ₹${_totalValue.toStringAsFixed(2)}'
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to calculate SIP: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryYellow,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'SIP Calculator',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
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
                    "1. Enter your monthly investment amount.\n2. Enter the expected annual return rate.\n3. Enter the investment duration in years.\n4. Tap 'Calculate' to see your future wealth.", style: AppTextStyles.bodyText.copyWith(fontSize: 14),
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
                  _buildInputRow('Monthly Investment (₹)', _amountController, 'e.g., 5000'),
                  const SizedBox(height: 16),
                  _buildInputRow('Expected Return Rate (%)', _rateController, 'e.g., 12'),
                  const SizedBox(height: 16),
                  _buildInputRow('Time Period (Years)', _yearsController, 'e.g., 10'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_totalValue > 0)
              NeoCard(
                backgroundColor: AppColors.primaryYellow,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildResultRow('Invested Amount', _investedAmount),
                    const SizedBox(height: 12),
                    _buildResultRow('Est. Returns', _estReturns),
                    const Divider(color: Colors.black, thickness: 2, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Value', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('₹${_totalValue.toStringAsFixed(0)}', style: AppTextStyles.heroTitle.copyWith(color: Colors.black, fontSize: 24)),
                      ],
                    ),
                  ],
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primaryYellow),
                ),
              ),
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildHistoryCard(),
            ],
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
              borderSide: const BorderSide(color: AppColors.primaryYellow, width: 2),
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
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 16)),
        Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
  Widget _buildHistoryCard() {
    return NeoCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent History', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('sip_history');
                  setState(() {
                    _history.clear();
                  });
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._history.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry['input'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(entry['result'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(entry['calculatedOn'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

}