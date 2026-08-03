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

class GstCalculatorScreen extends ConsumerStatefulWidget {
  const GstCalculatorScreen({super.key});

  @override
  ConsumerState<GstCalculatorScreen> createState() => _GstCalculatorScreenState();
}

class _GstCalculatorScreenState extends ConsumerState<GstCalculatorScreen> {

  List<Map<String, dynamic>> _history = [];
  static const String _historyKey = 'gst_history';

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
  double _gstRate = 18.0;
  bool _isAddGst = true; // true = Add GST, false = Subtract GST
  bool _isLoading = false;
  
  double _gstAmount = 0.0;
  double _totalAmount = 0.0;
  double _originalAmount = 0.0;

  Future<void> _calculate() async {
    double amt = double.tryParse(_amountController.text) ?? 0.0;
    if (amt == 0) {
      setState(() {
        _gstAmount = 0;
        _totalAmount = 0;
        _originalAmount = 0;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref.read(dailyUtilityServiceProvider).calculateGst(
        amount: amt,
        gstRate: _gstRate,
        isInclusive: !_isAddGst,
      );

      setState(() {
        _originalAmount = (result['net_amount'] as num).toDouble();
        _gstAmount = (result['gst_amount'] as num).toDouble();
        _totalAmount = (result['total_amount'] as num).toDouble();
        _isLoading = false;
      });
      _saveToHistory(
        'Amt: ₹${_amountController.text}, Rate: $_gstRate% (${_isAddGst ? "+GST" : "-GST"})',
        'Total: ₹${_totalAmount.toStringAsFixed(2)}'
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to calculate GST: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPink,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'GST Calculator',
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
                    "1. Enter the initial amount.\n2. Enter the GST percentage.\n3. Select whether to Add or Remove GST.\n4. Tap 'Calculate' to see the final price.", style: AppTextStyles.bodyText.copyWith(fontSize: 14),
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
                  Row(
                    children: [
                      Expanded(child: _buildTypeToggle('Add GST (+)', true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTypeToggle('Remove GST (-)', false)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Amount', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixText: '₹ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryPink, width: 2),
                      ),
                    ),
                    onChanged: (_) => _calculate(),
                  ),
                  const SizedBox(height: 20),
                  Text('GST Rate: ${_gstRate.toInt()}%', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
                  Slider(
                    value: _gstRate,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: AppColors.primaryPink,
                    onChanged: (val) {
                      setState(() => _gstRate = val);
                      _calculate();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [5.0, 12.0, 18.0, 28.0].map((rate) {
                      return GestureDetector(
                        onTap: () {
                          setState(() => _gstRate = rate);
                          _calculate();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _gstRate == rate ? AppColors.primaryPink : Colors.grey[200],
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${rate.toInt()}%', style: TextStyle(
                            color: _gstRate == rate ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          )),
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_totalAmount > 0)
              NeoCard(
                backgroundColor: AppColors.primaryPink,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildResultRow('Original Amount', _originalAmount),
                    const SizedBox(height: 12),
                    _buildResultRow('${_isAddGst ? '+' : '-'} GST (${_gstRate.toInt()}%)', _gstAmount),
                    const Divider(color: Colors.white, thickness: 2, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('₹${_totalAmount.toStringAsFixed(2)}', style: AppTextStyles.heroTitle.copyWith(color: Colors.white, fontSize: 24)),
                      ],
                    ),
                  ],
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primaryPink),
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

  Widget _buildTypeToggle(String label, bool isAdd) {
    final isSelected = _isAddGst == isAdd;
    return GestureDetector(
      onTap: () {
        setState(() => _isAddGst = isAdd);
        _calculate();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                  await prefs.remove('gst_history');
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