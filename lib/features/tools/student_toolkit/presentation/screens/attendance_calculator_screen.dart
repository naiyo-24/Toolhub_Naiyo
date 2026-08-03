import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../providers/student_toolkit_providers.dart';

class AttendanceCalculatorScreen extends ConsumerStatefulWidget {
  const AttendanceCalculatorScreen({super.key});

  @override
  ConsumerState<AttendanceCalculatorScreen> createState() => _AttendanceCalculatorScreenState();
}

class _AttendanceCalculatorScreenState extends ConsumerState<AttendanceCalculatorScreen> {
  final _totalClassesController = TextEditingController();
  final _classesAttendedController = TextEditingController();
  final _targetPercentageController = TextEditingController(text: '75');
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _result;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('attendance_history');
    if (historyJson != null) {
      final List<dynamic> decoded = json.decode(historyJson);
      setState(() {
        _history = List<Map<String, dynamic>>.from(decoded);
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('attendance_history', json.encode(_history));
  }

  Future<void> _calculate() async {
    final total = int.tryParse(_totalClassesController.text);
    final attended = int.tryParse(_classesAttendedController.text);
    final target = double.tryParse(_targetPercentageController.text);

    if (total == null || attended == null || target == null) {
      setState(() => _error = 'Please enter valid numbers in all fields.');
      return;
    }

    if (attended > total) {
      setState(() => _error = 'Classes attended cannot be greater than total classes.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final service = ref.read(studentToolkitServiceProvider);
      final res = await service.calculateAttendance(total, attended, target);
      setState(() {
        _result = res;
        
        _history.insert(0, {
          'title': 'Result: ${res['current_percentage']}% (${res['status']})',
          'subtitle': 'Attended: $attended/$total | Target: $target%'
        });
        
        if (_history.length > 10) {
          _history.removeLast();
        }
      });
      _saveHistory();
    } catch (e) {
      setState(() {
        _error = 'Failed to calculate attendance. Check your inputs.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _totalClassesController.dispose();
    _classesAttendedController.dispose();
    _targetPercentageController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint ?? '0',
            filled: true,
            fillColor: Colors.white,
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
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: Text('Attendance Calc', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
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
                    "1. Enter your total classes held and attended.\n2. Set your target attendance percentage.\n3. Tap 'Calculate' to see how many classes you need to attend or can afford to miss.",
                    style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            NeoCard(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildTextField('Total Classes Conducted', _totalClassesController),
                  const SizedBox(height: 16),
                  _buildTextField('Classes Attended', _classesAttendedController),
                  const SizedBox(height: 16),
                  _buildTextField('Target Percentage (%)', _targetPercentageController, hint: '75'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      onPressed: _isLoading ? null : _calculate,
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('Calculate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              NeoCard(
                backgroundColor: _result!['status'] == 'Safe' ? AppColors.primaryYellow : AppColors.primaryRed,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Current: ${_result!['current_percentage']}%', 
                      style: AppTextStyles.heroTitle.copyWith(fontSize: 32)
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _result!['message'], 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 20),
              NeoCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('History (Last 10)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    ..._history.map((h) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history_rounded, size: 20, color: Colors.black54),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(h['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(h['subtitle'], style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
