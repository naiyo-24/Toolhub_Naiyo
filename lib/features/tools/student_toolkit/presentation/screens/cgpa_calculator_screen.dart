import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../providers/student_toolkit_providers.dart';

class SemesterInput {
  final TextEditingController sgpaController = TextEditingController();
  final TextEditingController creditsController = TextEditingController();

  void dispose() {
    sgpaController.dispose();
    creditsController.dispose();
  }
}

class CgpaCalculatorScreen extends ConsumerStatefulWidget {
  const CgpaCalculatorScreen({super.key});

  @override
  ConsumerState<CgpaCalculatorScreen> createState() => _CgpaCalculatorScreenState();
}

class _CgpaCalculatorScreenState extends ConsumerState<CgpaCalculatorScreen> {
  final List<SemesterInput> _semesters = List.generate(8, (_) => SemesterInput());
  
  bool _isLoading = false;
  double? _resultCgpa;
  double? _resultPercentage;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('cgpa_history_makaut');
    if (historyJson != null) {
      final List<dynamic> decoded = json.decode(historyJson);
      setState(() {
        _history = List<Map<String, dynamic>>.from(decoded);
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cgpa_history_makaut', json.encode(_history));
  }

  Future<void> _calculate() async {
    List<Map<String, dynamic>> validSemesters = [];
    double totalCredits = 0;
    int semCount = 0;

    for (var sem in _semesters) {
      final sgpa = double.tryParse(sem.sgpaController.text);
      final credits = double.tryParse(sem.creditsController.text);

      if (sgpa != null && credits != null && credits > 0) {
        validSemesters.add({
          'sgpa': sgpa,
          'credits': credits,
        });
        totalCredits += credits;
        semCount++;
      }
    }

    if (validSemesters.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final service = ref.read(studentToolkitServiceProvider);
        final res = await service.calculateCgpa(validSemesters);
        final cgpa = (res['cgpa'] as num).toDouble();
        final percentage = (cgpa - 0.75) * 10;
        
        setState(() {
          _resultCgpa = cgpa;
          _resultPercentage = percentage;
          
          _history.insert(0, {
            'title': 'Result: ${cgpa.toStringAsFixed(2)} CGPA',
            'subtitle': 'Based on $semCount semester(s) | Credits: ${totalCredits.toInt()}'
          });
          
          if (_history.length > 10) {
            _history.removeLast();
          }
        });
        _saveHistory();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to calculate CGPA using backend.', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid SGPA and Credits for at least one semester.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addSemester() {
    setState(() {
      _semesters.add(SemesterInput());
    });
  }

  void _removeSemester(int index) {
    if (_semesters.length > 1) {
      setState(() {
        final sem = _semesters.removeAt(index);
        sem.dispose();
      });
    }
  }

  void _resetCalculator() {
    setState(() {
      for (var sem in _semesters) {
        sem.sgpaController.clear();
        sem.creditsController.clear();
      }
      _resultCgpa = null;
      _resultPercentage = null;
    });
  }

  @override
  void dispose() {
    for (var sem in _semesters) {
      sem.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPink,
        elevation: 0,
        centerTitle: true,
        title: Text('CGPA Calculator', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            NeoCard(
              backgroundColor: const Color(0xFFE0FBFC),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.black),
                      const SizedBox(width: 8),
                      Text('MAKAUT Formula', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "CGPA is the weighted average of grade points earned across all completed semesters. Calculated by dividing the total of each semester's credit-weighted grade points (SGPA × Credits) by the total credits registered.",
                    style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Semesters', style: AppTextStyles.sectionTitle.copyWith(fontSize: 20)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.red),
                      onPressed: _resetCalculator,
                      tooltip: 'Reset All',
                    ),
                    ElevatedButton.icon(
                      onPressed: _addSemester,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            NeoCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    children: [
                      SizedBox(width: 40, child: Text('Sem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(child: Text('SGPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(child: Text('Credits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      SizedBox(width: 40),
                    ],
                  ),
                  const Divider(color: Colors.black, thickness: 1.5),
                  const SizedBox(height: 8),
                  ..._semesters.asMap().entries.map((entry) {
                    int idx = entry.key;
                    SemesterInput sem = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.black, width: 1.5),
                              ),
                              child: Center(child: Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: sem.sgpaController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'e.g. 8.5',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: sem.creditsController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'e.g. 20',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 32,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              onPressed: _semesters.length > 1 ? () => _removeSemester(idx) : null,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _calculate,
                      child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('Calculate CGPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),

            if (_resultCgpa != null) ...[
              const SizedBox(height: 20),
              NeoCard(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Overall CGPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text(_resultCgpa!.toStringAsFixed(2), style: AppTextStyles.heroTitle.copyWith(fontSize: 56)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Est. Percentage*', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                              Text('${_resultPercentage!.toStringAsFixed(2)}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primaryBlue)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('*Using standard MAKAUT formula: (CGPA - 0.75) × 10', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
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
