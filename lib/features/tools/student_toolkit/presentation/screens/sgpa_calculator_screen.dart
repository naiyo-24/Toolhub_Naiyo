import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../providers/student_toolkit_providers.dart';

class SgpaCalculatorScreen extends ConsumerStatefulWidget {
  const SgpaCalculatorScreen({super.key});

  @override
  ConsumerState<SgpaCalculatorScreen> createState() => _SgpaCalculatorScreenState();
}

class _SgpaCalculatorScreenState extends ConsumerState<SgpaCalculatorScreen> {
  final List<Map<String, TextEditingController>> _courses = [
    {'credits': TextEditingController(), 'grade_points': TextEditingController()},
    {'credits': TextEditingController(), 'grade_points': TextEditingController()},
    {'credits': TextEditingController(), 'grade_points': TextEditingController()},
  ];
  
  bool _isLoading = false;
  String? _error;
  double? _resultSgpa;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('sgpa_history');
    if (historyJson != null) {
      final List<dynamic> decoded = json.decode(historyJson);
      setState(() {
        _history = List<Map<String, dynamic>>.from(decoded);
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sgpa_history', json.encode(_history));
  }

  void _addCourse() {
    setState(() {
      _courses.add({'credits': TextEditingController(), 'grade_points': TextEditingController()});
    });
  }

  void _removeCourse(int index) {
    if (_courses.length > 1) {
      setState(() {
        _courses[index]['credits']!.dispose();
        _courses[index]['grade_points']!.dispose();
        _courses.removeAt(index);
      });
    }
  }

  Future<void> _calculate() async {
    List<Map<String, dynamic>> parsedCourses = [];
    int totalCredits = 0;
    
    for (var course in _courses) {
      final creditsText = course['credits']!.text;
      final pointsText = course['grade_points']!.text;
      
      // Skip empty rows
      if (creditsText.isEmpty && pointsText.isEmpty) continue;

      final credits = int.tryParse(creditsText);
      final points = double.tryParse(pointsText);

      if (credits == null || points == null) {
        setState(() => _error = 'Please enter valid numbers for filled rows.');
        return;
      }
      parsedCourses.add({'credits': credits, 'grade_points': points});
      totalCredits += credits;
    }

    if (parsedCourses.isEmpty) {
      setState(() => _error = 'Please enter at least one course.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _resultSgpa = null;
    });

    try {
      final service = ref.read(studentToolkitServiceProvider);
      final res = await service.calculateSgpa(parsedCourses);
      final finalSgpa = (res['sgpa'] as num).toDouble();
      
      setState(() {
        _resultSgpa = finalSgpa;
        
        _history.insert(0, {
          'title': 'Result: ${finalSgpa.toStringAsFixed(2)} SGPA',
          'subtitle': 'Courses: ${parsedCourses.length} | Total Credits: $totalCredits'
        });
        
        if (_history.length > 10) {
          _history.removeLast();
        }
      });
      _saveHistory();
    } catch (e) {
      setState(() {
        _error = 'Failed to calculate SGPA. Check your inputs.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (var c in _courses) {
      c['credits']!.dispose();
      c['grade_points']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: Text('SGPA Calculator', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
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
                    "1. Enter the credits and grades for each of your subjects.\n2. Add more subjects if needed.\n3. Tap 'Calculate SGPA' to see your semester performance.",
                    style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            NeoCard(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Enter your courses below:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Text('Credits', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 16),
                      Expanded(child: Text('Grade Points (1-10)', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 48), // Space for delete icon
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_courses.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _courses[index]['credits'],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'e.g. 3',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _courses[index]['grade_points'],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'e.g. 8.5',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded),
                            onPressed: _courses.length > 1 ? () => _removeCourse(index) : null,
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _addCourse,
                    icon: const Icon(Icons.add_rounded, color: Colors.black),
                    label: const Text('Add Course', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
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
                          : const Text('Calculate SGPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
            if (_resultSgpa != null) ...[
              const SizedBox(height: 20),
              NeoCard(
                backgroundColor: AppColors.primaryYellow,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Your SGPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(_resultSgpa!.toStringAsFixed(2), style: AppTextStyles.heroTitle.copyWith(fontSize: 48)),
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
