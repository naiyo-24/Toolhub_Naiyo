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


class EmiCalculatorScreen extends ConsumerStatefulWidget {
  const EmiCalculatorScreen({super.key});

  @override
  ConsumerState<EmiCalculatorScreen> createState() => _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends ConsumerState<EmiCalculatorScreen> {

  List<Map<String, dynamic>> _history = [];
  static const String _historyKey = 'emi_history';

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
  final _tenureController = TextEditingController();
  
  bool _isYears = true;
  bool _isLoading = false;
  
  double _emi = 0.0;
  double _totalInterest = 0.0;
  double _totalPayment = 0.0;

  Future<void> _calculateEMI() async {
    
    double p = double.tryParse(_amountController.text) ?? 0.0;
    double rAnnual = double.tryParse(_rateController.text) ?? 0.0;
    double n = double.tryParse(_tenureController.text) ?? 0.0;
    
    if (p <= 0 || rAnnual <= 0 || n <= 0) {
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
      if (_isYears) {
        n = n * 12; // Convert years to months for API
      }

      final result = await ref.read(dailyUtilityServiceProvider).calculateEmi(
        principal: p,
        annualRate: rAnnual,
        tenureMonths: n.toInt(),
      );

      setState(() {
        _emi = (result['emi'] as num).toDouble();
        _totalPayment = (result['total_payment'] as num).toDouble();
        _totalInterest = (result['total_interest'] as num).toDouble();
        _isLoading = false;
      });
      _saveToHistory(
        '₹${_amountController.text} at ${_rateController.text}% for ${_tenureController.text} ${_isYears ? 'Yrs' : 'Mos'}', 
        'EMI: ₹${_emi.toStringAsFixed(2)}'
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to calculate EMI: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'EMI Calculator',
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    "1. Enter the principal loan amount.\n2. Enter the annual interest rate.\n3. Enter the loan tenure in years.\n4. Tap 'Calculate' to see your monthly EMI.", style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildInputCard(),
            const SizedBox(height: 24),
            _buildResultCard(),
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildHistoryCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return NeoCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: 'Loan Amount (₹)',
            controller: _amountController,
            hint: 'e.g., 500000',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Interest Rate (% p.a.)',
            controller: _rateController,
            hint: 'e.g., 8.5',
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  label: 'Loan Tenure',
                  controller: _tenureController,
                  hint: 'e.g., 5',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() { _isYears = true; _calculateEMI(); }),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _isYears ? AppColors.primaryPurple : Colors.transparent,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
                            ),
                            child: Text('Yr', style: TextStyle(fontWeight: FontWeight.bold, color: _isYears ? Colors.white : Colors.black)),
                          ),
                        ),
                      ),
                      Container(width: 2, color: Colors.black),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() { _isYears = false; _calculateEMI(); }),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: !_isYears ? AppColors.primaryPurple : Colors.transparent,
                              borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
                            ),
                            child: Text('Mo', style: TextStyle(fontWeight: FontWeight.bold, color: !_isYears ? Colors.white : Colors.black)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () {
                  FocusScope.of(context).unfocus();
                  _calculateEMI();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      'Calculate EMI',
                      style: AppTextStyles.buttonText.copyWith(color: Colors.white),
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required String hint}) {
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
            ),
          ),
          onChanged: (_) => _calculateEMI(),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return NeoCard(
      backgroundColor: AppColors.primaryPurple,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Monthly EMI',
            style: AppTextStyles.sectionTitle.copyWith(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_emi.toStringAsFixed(2)}',
            style: AppTextStyles.heroTitle.copyWith(color: Colors.white, fontSize: 36),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white30, thickness: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildResultStat('Total Interest', '₹${_totalInterest.toStringAsFixed(2)}'),
              _buildResultStat('Total Payment', '₹${_totalPayment.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
                  await prefs.remove('emi_history');
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