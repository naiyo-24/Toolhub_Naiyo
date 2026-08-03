import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';

class AssignmentPlannerScreen extends StatefulWidget {
  const AssignmentPlannerScreen({super.key});

  @override
  State<AssignmentPlannerScreen> createState() => _AssignmentPlannerScreenState();
}

class _AssignmentPlannerScreenState extends State<AssignmentPlannerScreen> {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  DateTime? _selectedDueDate;
  List<Map<String, dynamic>> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? assignmentsJson = prefs.getString('student_assignments');
    if (assignmentsJson != null) {
      final List<dynamic> decoded = json.decode(assignmentsJson);
      setState(() {
        _assignments = List<Map<String, dynamic>>.from(decoded);
      });
    }
  }

  Future<void> _saveAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_assignments', json.encode(_assignments));
  }

  Future<void> _pickDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryPurple,
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
        _selectedDueDate = picked;
      });
    }
  }

  void _addAssignment() {
    final title = _titleController.text.trim();
    final subject = _subjectController.text.trim();
    
    if (title.isEmpty || _selectedDueDate == null) return;

    setState(() {
      _assignments.add({
        'title': title,
        'subject': subject.isEmpty ? 'General' : subject,
        'due_date': _selectedDueDate!.toIso8601String(),
        'completed': false,
      });
      
      // Sort by due date
      _assignments.sort((a, b) => DateTime.parse(a['due_date']).compareTo(DateTime.parse(b['due_date'])));
      
      _titleController.clear();
      _subjectController.clear();
      _selectedDueDate = null;
    });
    _saveAssignments();
  }

  void _toggleAssignment(int index) {
    setState(() {
      _assignments[index]['completed'] = !_assignments[index]['completed'];
    });
    _saveAssignments();
  }

  void _deleteAssignment(int index) {
    setState(() {
      _assignments.removeAt(index);
    });
    _saveAssignments();
  }

  int _calculateDaysLeft(String dateStr) {
    final dueDate = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = dueDate.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        centerTitle: true,
        title: Text('Assignment Planner', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: NeoCard(
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
                      "1. Enter assignment title, subject, and due date.\n2. Tap 'Add Assignment'.\n3. Check off assignments as you complete them.",
                      style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20),
              child: NeoCard(
                backgroundColor: AppColors.primaryPurple,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('New Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Assignment Title',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _subjectController,
                            decoration: InputDecoration(
                              hintText: 'Subject',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(0, 55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.black, width: 2)),
                            ),
                            onPressed: _pickDueDate,
                            icon: const Icon(Icons.calendar_today_rounded, size: 18),
                            label: Text(
                              _selectedDueDate == null 
                                ? 'Due Date' 
                                : '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _addAssignment,
                      child: const Text('Add Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
            if (_assignments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: NeoCard(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assignments (Last 10)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),
                      ..._assignments.take(10).toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final assignment = entry.value;
                        final daysLeft = _calculateDaysLeft(assignment['due_date']);
                        final isCompleted = assignment['completed'];
                        
                        Color bgCol = Colors.grey[100]!;
                        if (isCompleted) {
                          bgCol = Colors.green.shade50;
                        } else if (daysLeft < 0) {
                          bgCol = Colors.red.shade50;
                        } else if (daysLeft <= 2) {
                          bgCol = AppColors.primaryYellow.withValues(alpha: 0.2);
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bgCol,
                            border: Border.all(color: Colors.black, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isCompleted,
                                onChanged: (_) => _toggleAssignment(index),
                                activeColor: Colors.black,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      assignment['title'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                        color: isCompleted ? Colors.black54 : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${assignment['subject']} • ${daysLeft < 0 ? 'Overdue by ${daysLeft.abs()} days' : daysLeft == 0 ? 'Due Today' : 'Due in $daysLeft days'}',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: isCompleted ? Colors.black38 : Colors.black87, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_rounded, size: 20, color: Colors.black54),
                                onPressed: () => _deleteAssignment(index),
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
              ),
              const SizedBox(height: 40),
            ] else ...[
              const SizedBox(height: 40),
              const Center(child: Text('No assignments pending! 🎉', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            ],
          ],
        ),
      ),
    );
  }
}
