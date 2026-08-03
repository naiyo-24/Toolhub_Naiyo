import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  // Map of Day -> List of classes (String)
  Map<String, List<String>> _timetable = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
    'Sunday': [],
  };

  String _selectedDay = 'Monday';
  final _classController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ttJson = prefs.getString('student_timetable');
    if (ttJson != null) {
      final Map<String, dynamic> decoded = json.decode(ttJson);
      setState(() {
        _timetable = decoded.map((key, value) => MapEntry(key, List<String>.from(value)));
      });
    }
  }

  Future<void> _saveTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_timetable', json.encode(_timetable));
  }

  void _addClass() {
    final className = _classController.text.trim();
    if (className.isEmpty) return;

    setState(() {
      _timetable[_selectedDay]!.add(className);
      _classController.clear();
    });
    _saveTimetable();
  }

  void _deleteClass(String day, int index) {
    setState(() {
      _timetable[day]!.removeAt(index);
    });
    _saveTimetable();
  }

  @override
  void dispose() {
    _classController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryYellow,
        elevation: 0,
        centerTitle: true,
        title: Text('Timetable', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Instructions
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
                      "1. Select a day of the week.\n2. Tap '+' to add your classes, subjects, and timings.\n3. View your daily schedule at a glance.",
                      style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Day Selector
            Container(
              height: 60,
              color: AppColors.primaryYellow,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _timetable.keys.length,
                itemBuilder: (context, index) {
                  final day = _timetable.keys.elementAt(index);
                  final isSelected = day == _selectedDay;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = day;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          day.substring(0, 3), 
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  NeoCard(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _classController,
                            decoration: InputDecoration(
                              hintText: 'e.g. 10:00 AM - Physics',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                            ),
                            onSubmitted: (_) => _addClass(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_box_rounded, size: 40, color: AppColors.primaryGreen),
                          onPressed: _addClass,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  if (_timetable[_selectedDay]!.isNotEmpty) ...[
                    NeoCard(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$_selectedDay Classes (Last 10)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 12),
                          ..._timetable[_selectedDay]!.take(10).toList().asMap().entries.map((entry) {
                            final index = entry.key;
                            final schedule = entry.value;
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
                                  Expanded(child: Text(schedule, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded, size: 20, color: Colors.black54),
                                    onPressed: () => _deleteClass(_selectedDay, index),
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
                  ] else ...[
                    const SizedBox(height: 40),
                    const Center(child: Text('No classes scheduled for this day!', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
