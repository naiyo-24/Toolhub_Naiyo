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

class PercentageCalculatorScreen extends ConsumerStatefulWidget {
  const PercentageCalculatorScreen({super.key});

  @override
  ConsumerState<PercentageCalculatorScreen> createState() => _PercentageCalculatorScreenState();
}

class _PercentageCalculatorScreenState extends ConsumerState<PercentageCalculatorScreen> {

  List<Map<String, dynamic>> _history = [];
  static const String _historyKey = 'percentage_history';

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

  final _val1Controller = TextEditingController();
  final _val2Controller = TextEditingController();
  final _val3Controller = TextEditingController();
  final _val4Controller = TextEditingController();

  String _res1 = '0';
  String _res2 = '0';

  void _calc1() {
    double v1 = double.tryParse(_val1Controller.text) ?? 0;
    double v2 = double.tryParse(_val2Controller.text) ?? 0;
    
    if (v1 == 0 || v2 == 0) {
      setState(() => _res1 = '0');
      return;
    }
    
    double res = (v1 / 100) * v2;
    setState(() {
      _res1 = res.toStringAsFixed(2).replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), '');
    });
    _saveToHistory('${_val1Controller.text}% of ${_val2Controller.text}', _res1);
  }

  Future<void> _calc2() async {
    double v3 = double.tryParse(_val3Controller.text) ?? 0;
    double v4 = double.tryParse(_val4Controller.text) ?? 0;
    
    if (v3 == 0 || v4 == 0) {
      setState(() => _res2 = '0');
      return;
    }
    
    try {
      final result = await ref.read(dailyUtilityServiceProvider).calculatePercentage(v3, v4);
      setState(() {
        _res2 = (result['percentage'] as num).toString();
      });
      _saveToHistory('${_val3Controller.text} out of ${_val4Controller.text}', '$_res2%');
    } catch (e) {
      // Fallback or error handling
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
          'Percentage Calculator',
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
                    "1. Use the first box to find 'X% of Y'.\n2. Use the second box to find what percentage 'X is out of Y'.", style: AppTextStyles.bodyText.copyWith(fontSize: 14),
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
                  Text('What is X% of Y?', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_val1Controller, 'X', _calc1),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('% of', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      Expanded(
                        child: _buildTextField(_val2Controller, 'Y', _calc1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Text('Result = ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(_res1, style: AppTextStyles.heroTitle.copyWith(color: Colors.white, fontSize: 24)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            NeoCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('X is what % of Y?', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_val3Controller, 'X', _calc2),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('is what % of', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Expanded(
                        child: _buildTextField(_val4Controller, 'Y', _calc2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Text('Result = ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('$_res2%', style: AppTextStyles.heroTitle.copyWith(color: Colors.black, fontSize: 24)),
                      ],
                    ),
                  )
                ],
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

  Widget _buildTextField(TextEditingController controller, String hint, VoidCallback onChanged) {
    return TextField(
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
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      onChanged: (_) => onChanged(),
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
                  await prefs.remove('percentage_history');
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