import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../../providers/daily_utility_providers.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AgeCalculatorScreen extends ConsumerStatefulWidget {
  const AgeCalculatorScreen({super.key});

  @override
  ConsumerState<AgeCalculatorScreen> createState() => _AgeCalculatorScreenState();
}

class _AgeCalculatorScreenState extends ConsumerState<AgeCalculatorScreen> {
  DateTime? _dob;
  
  int _years = 0;
  int _months = 0;
  int _days = 0;
  int _totalDays = 0;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _history = [];
  static const String _historyKey = 'age_calculator_history';

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

  Future<void> _saveToHistory(String dob, String ageStr) async {
    final prefs = await SharedPreferences.getInstance();
    
    final entry = {
      'dob': dob,
      'age': ageStr,
      'calculatedOn': DateFormat('dd MMM yyyy HH:mm').format(DateTime.now()),
    };
    
    _history.insert(0, entry);
    
    if (_history.length > 10) {
      _history = _history.sublist(0, 10);
    }
    
    await prefs.setString(_historyKey, jsonEncode(_history));
    setState(() {});
  }

  Future<void> _calculateAge() async {
    if (_dob == null) return;

    final now = DateTime.now();
    if (_dob!.isAfter(now)) {
      // Invalid DOB
      setState(() {
        _years = 0;
        _months = 0;
        _days = 0;
        _totalDays = 0;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_dob!);
      final result = await ref.read(dailyUtilityServiceProvider).calculateAge(formattedDate);

      setState(() {
        _years = result['years'] as int;
        _months = result['months'] as int;
        _days = result['days'] as int;
        _totalDays = result['total_days'] ?? 0;
        _isLoading = false;
      });
      _saveToHistory(DateFormat('dd MMM yyyy').format(_dob!), '$_years Years, $_months Months, $_days Days');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to calculate Age: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime.now().subtract(const Duration(days: 365 * 20)), // Default ~20 years old
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
      });
      _calculateAge();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dobText = _dob == null ? 'Select Date of Birth' : DateFormat('dd MMM yyyy').format(_dob!);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Age Calculator',
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
                    '1. Tap on the "Select Date of Birth" box below.\n'
                    '2. Choose your birth date from the calendar.\n'
                    '3. Your exact age in years, months, and days will automatically appear!', style: AppTextStyles.bodyText.copyWith(fontSize: 14),
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
                  Text('Date of Birth', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dobText,
                            style: TextStyle(
                              color: _dob == null ? Colors.black54 : Colors.black,
                              fontSize: 16,
                              fontWeight: _dob == null ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                          const Icon(Icons.calendar_today_rounded, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildResultCard(),
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 20),
              NeoCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Calculations', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                        TextButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove(_historyKey);
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('DOB: ${entry['dob']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(entry['age'], style: const TextStyle(color: Colors.black87, fontSize: 13)),
                                  ],
                                ),
                                Text(entry['calculatedOn'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (_dob == null) {
      return const SizedBox.shrink();
    }

    return NeoCard(
      backgroundColor: AppColors.primaryBlue,
      padding: const EdgeInsets.all(24),
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : Column(
            children: [
              Text(
            'Current Age',
            style: AppTextStyles.sectionTitle.copyWith(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeBlock('$_years', 'Years'),
              _buildTimeBlock('$_months', 'Months'),
              _buildTimeBlock('$_days', 'Days'),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white30, thickness: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Days Lived', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
              Text('$_totalDays', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBlock(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.heroTitle.copyWith(color: Colors.white, fontSize: 32)),
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }
}
