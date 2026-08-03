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

class BmiCalculatorScreen extends ConsumerStatefulWidget {
  const BmiCalculatorScreen({super.key});

  @override
  ConsumerState<BmiCalculatorScreen> createState() => _BmiCalculatorScreenState();
}

class _BmiCalculatorScreenState extends ConsumerState<BmiCalculatorScreen> {

  List<Map<String, dynamic>> _history = [];
  static const String _historyKey = 'bmi_history';

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

  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  
  bool _isMetric = true; // true = cm/kg, false = in/lbs
  
  double _bmi = 0.0;
  String _category = '';
  Color _categoryColor = Colors.white;
  bool _isLoading = false;

  Future<void> _calculateBMI() async {
    
    double h = double.tryParse(_heightController.text) ?? 0.0;
    double w = double.tryParse(_weightController.text) ?? 0.0;
    
    if (h <= 0 || w <= 0) {
      setState(() {
        _bmi = 0;
        _category = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      double heightCm = h;
      double weightKg = w;

      if (!_isMetric) {
        // Convert feet to cm
        heightCm = h * 30.48;
        // Convert lbs to kg
        weightKg = w * 0.453592;
      }

      int age = int.tryParse(_ageController.text) ?? 25;

      final result = await ref.read(dailyUtilityServiceProvider).calculateBmi(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
      );

      double bmiVal = (result['bmi'] as num).toDouble();
      String cat = result['category'] as String;
      Color col = Colors.white;

      if (cat == 'Underweight') {
        col = Colors.blueAccent;
      } else if (cat == 'Normal weight') {
        col = Colors.greenAccent;
      } else if (cat == 'Overweight') {
        col = Colors.orangeAccent;
      } else {
        col = Colors.redAccent;
      }

      setState(() {
        _bmi = bmiVal;
        _category = cat;
        _categoryColor = col;
        _isLoading = false;
      });
      _saveToHistory(
        '${_weightController.text} ${_isMetric ? 'kg' : 'lbs'}, ${_heightController.text} ${_isMetric ? 'cm' : 'in'}',
        'BMI: ${_bmi.toStringAsFixed(1)} ($_category)'
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to calculate BMI: $e')),
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
          'BMI Calculator',
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
              backgroundColor: const Color(0xFFFCE0EB), // Light Pink tint
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
                    "1. Enter your age.\n"
                    "2. Enter your height and weight.\n"
                    "3. Tap 'Calculate' to find your Body Mass Index and health category.",
                    style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildInputCard(),
            const SizedBox(height: 24),
            if (_bmi > 0) _buildResultCard(),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUnitToggle('Metric', true),
              const SizedBox(width: 16),
              _buildUnitToggle('Imperial', false),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            label: 'Age',
            controller: _ageController,
            hint: 'e.g., 25',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: _isMetric ? 'Height (cm)' : 'Height (foot)',
            controller: _heightController,
            hint: _isMetric ? 'e.g., 175' : 'e.g., 5.8',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: _isMetric ? 'Weight (kg)' : 'Weight (lbs)',
            controller: _weightController,
            hint: _isMetric ? 'e.g., 70' : 'e.g., 150',
          ),
          const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () {
                  FocusScope.of(context).unfocus();
                  _calculateBMI();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
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
                      'Calculate BMI',
                      style: AppTextStyles.buttonText.copyWith(color: Colors.white),
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(String label, bool isMetricOpt) {
    final isSelected = _isMetric == isMetricOpt;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMetric = isMetricOpt;
          _heightController.clear();
          _weightController.clear();
          _bmi = 0;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(20),
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
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
          onChanged: (_) => _calculateBMI(),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return NeoCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Your BMI Score',
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            _bmi.toStringAsFixed(1),
            style: AppTextStyles.heroTitle.copyWith(color: Colors.black, fontSize: 48),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _categoryColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Text(
              _category.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        ],
      ),
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
                  await prefs.remove('bmi_history');
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