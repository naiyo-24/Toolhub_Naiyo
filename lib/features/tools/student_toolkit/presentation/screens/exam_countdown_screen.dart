import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../providers/student_toolkit_providers.dart';

class ExamCountdownScreen extends ConsumerStatefulWidget {
  const ExamCountdownScreen({super.key});

  @override
  ConsumerState<ExamCountdownScreen> createState() => _ExamCountdownScreenState();
}

class _ExamCountdownScreenState extends ConsumerState<ExamCountdownScreen> {
  DateTime? _selectedDate;
  final TextEditingController _subjectController = TextEditingController();
  
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
    final String? historyJson = prefs.getString('exam_countdown_history');
    if (historyJson != null) {
      final List<dynamic> decoded = json.decode(historyJson);
      setState(() {
        _history = List<Map<String, dynamic>>.from(decoded);
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exam_countdown_history', json.encode(_history));
  }

  void _deleteHistoryItem(int index) {
    setState(() {
      _history.removeAt(index);
    });
    _saveHistory();
  }

  Future<void> _pickDate() async {
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject name first')),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _result = null;
      });
      _calculate();
    }
  }

  Future<void> _calculate() async {
    if (_selectedDate == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final service = ref.read(studentToolkitServiceProvider);
      // Format to YYYY-MM-DD
      final formattedDate = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      final res = await service.examCountdown(formattedDate);
      
      setState(() {
        _result = res;
        _history.insert(0, {
          'subject': _subjectController.text.trim(),
          'date': formattedDate,
          'result': res,
          'timestamp': DateTime.now().toIso8601String(),
        });
        if (_history.length > 10) {
          _history = _history.sublist(0, 10);
        }
      });
      _saveHistory();
      _subjectController.clear();
      _selectedDate = null;
      // ignore: use_build_context_synchronously
      FocusScope.of(context).unfocus();
    } catch (e) {
      setState(() {
        _error = 'Failed to calculate countdown. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        centerTitle: true,
        title: Text('Exam Countdown', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
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
                    "1. Enter the subject name for your upcoming exam.\n2. Tap 'Select Exam Date' to choose the date.\n3. See exactly how many days remain to prepare.",
                    style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            NeoCard(
              backgroundColor: AppColors.primaryRed,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.timer_rounded, size: 60, color: Colors.black),
                  const SizedBox(height: 16),
                  const Text('Select your exam date to see how much time is left to study!', 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), 
                    textAlign: TextAlign.center
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Final Math Exam',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      onPressed: _isLoading ? null : _pickDate,
                      icon: const Icon(Icons.calendar_today_rounded),
                      label: Text(
                        _selectedDate == null ? 'Select Exam Date' : 'Change Date',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppColors.primaryRed, strokeWidth: 4),
              ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              NeoCard(
                backgroundColor: AppColors.primaryYellow,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '${_result!['days_left']} Days', 
                      style: AppTextStyles.heroTitle.copyWith(fontSize: 48)
                    ),
                    Text(
                      '${_result!['hours_left']} Hours', 
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
                    const Text('Exam Deadlines (Last 10)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    ..._history.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final result = item['result'] as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['subject'] ?? 'Exam',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${result['days_left']} Days Left • ${item['date']}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, size: 20, color: Colors.black54),
                              onPressed: () => _deleteHistoryItem(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
