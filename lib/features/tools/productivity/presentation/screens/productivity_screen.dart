import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/widgets/universal_tool_card.dart';
import 'package:tool_hub/core/ads/banner_ad_widget.dart';


class ProductivityScreen extends StatefulWidget {
  const ProductivityScreen({super.key});

  @override
  State<ProductivityScreen> createState() => _ProductivityScreenState();
}

class _ProductivityScreenState extends State<ProductivityScreen> {
  String _searchQuery = '';
  bool _showAllTools = false;
  
  final List<Map<String, dynamic>> tools = [
      {'title': 'To-Do List', 'subtitle': 'Manage your tasks', 'icon': Icons.checklist_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Manage', 'endpoint': '/productivity-tools/todo', 'config': [
        {'key': 'title', 'label': 'Task Title', 'icon': Icons.title},
        {'key': 'description', 'label': 'Description', 'icon': Icons.description},
        {'key': 'due_date', 'label': 'Due Date (YYYY-MM-DD)', 'icon': Icons.calendar_today, 'type': 'datepicker'},
        {'key': 'priority', 'label': 'Priority', 'icon': Icons.priority_high, 'type': 'dropdown', 'options': ['Low', 'Medium', 'High']}
      ]},
      {'title': 'Notes', 'subtitle': 'Quick text notes', 'icon': Icons.notes_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Write', 'endpoint': '/productivity-tools/notes', 'config': [
        {'key': 'title', 'label': 'Note Title', 'icon': Icons.title},
        {'key': 'content', 'label': 'Content', 'icon': Icons.edit, 'type': 'text'}
      ]},
      {'title': 'Habit Tracker', 'subtitle': 'Track daily habits', 'icon': Icons.done_all_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Track', 'endpoint': '/health-tools/habit-tracker', 'config': [
        {'key': 'habit_name', 'label': 'Habit Name', 'icon': Icons.directions_run},
        {'key': 'frequency', 'label': 'Frequency', 'icon': Icons.repeat, 'type': 'dropdown', 'options': ['Daily', 'Weekly', 'Monthly']}
      ]},
      {'title': 'Pomodoro', 'subtitle': '25-minute timer', 'icon': Icons.timer_rounded, 'color': AppColors.primaryRed, 'actionText': 'Save Session', 'endpoint': '/productivity-tools/focus-timer', 'config': [
        {'key': 'session_type', 'label': 'Session Type', 'icon': Icons.category, 'type': 'dropdown', 'options': ['Pomodoro']},
        {'key': 'timer', 'type': 'pomodoro_timer', 'default_minutes': 25}
      ]},
      {'title': 'Focus Timer', 'subtitle': 'Custom focus sessions', 'icon': Icons.hourglass_bottom_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Save Session', 'endpoint': '/productivity-tools/focus-timer', 'config': [
        {'key': 'session_type', 'label': 'Session Type', 'icon': Icons.category, 'type': 'dropdown', 'options': ['Custom']},
        {'key': 'duration_minutes', 'label': 'Duration (Minutes)', 'icon': Icons.timer, 'type': 'number'},
        {'key': 'timer', 'type': 'pomodoro_timer', 'default_minutes': 0}
      ]},
      {'title': 'Voice Notes', 'subtitle': 'Record voice memos', 'icon': Icons.mic_rounded, 'color': AppColors.primaryPink, 'actionText': 'Record', 'endpoint': '/productivity-tools/voice-notes', 'config': [
        {'key': 'title', 'label': 'Recording Title', 'icon': Icons.title},
        {'key': 'voice_record', 'label': 'Record Audio', 'icon': Icons.mic, 'type': 'voice_recorder'}
      ]},
      {'title': 'Clipboard', 'subtitle': 'Manage copied items', 'icon': Icons.content_paste_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Manage', 'endpoint': '/productivity-tools/clipboard', 'config': [
        {'key': 'content', 'label': 'Content to Copy', 'icon': Icons.copy, 'type': 'text'}
      ]},
      {'title': 'Daily Journal', 'subtitle': 'Write your thoughts', 'icon': Icons.book_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Write', 'endpoint': '/productivity-tools/journal', 'config': [
        {'key': 'content', 'label': 'Journal Entry', 'icon': Icons.book, 'type': 'text'},
        {'key': 'mood', 'label': 'Mood', 'icon': Icons.mood, 'type': 'dropdown', 'options': ['Happy', 'Neutral', 'Sad', 'Excited', 'Tired']}
      ]},
      {'title': 'Goal Tracker', 'subtitle': 'Track long-term goals', 'icon': Icons.flag_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Track', 'endpoint': '/productivity-tools/goals', 'config': [
        {'key': 'title', 'label': 'Goal Title', 'icon': Icons.flag},
        {'key': 'target_date', 'label': 'Target Date (YYYY-MM-DD)', 'icon': Icons.calendar_today, 'type': 'datepicker'}
      ]},
      {'title': 'Reminder', 'subtitle': 'Set alerts & alarms', 'icon': Icons.notifications_active_rounded, 'color': AppColors.primaryRed, 'actionText': 'Set', 'endpoint': '/productivity-tools/reminders', 'config': [
        {'key': 'title', 'label': 'Reminder Title', 'icon': Icons.notifications},
        {'key': 'trigger_time', 'label': 'Trigger Time (HH:MM:SS)', 'icon': Icons.access_time, 'type': 'timepicker'}
      ]},
  ];

  void _navigateToTool(BuildContext context, Map<String, dynamic> tool) {
    context.push('/productivity/tool', extra: tool);
  }

  @override
  Widget build(BuildContext context) {
    var filteredTools = tools.where((tool) {
      final title = (tool['title'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query);
    }).toList();

    if (_searchQuery.isEmpty && !_showAllTools) {
      filteredTools = filteredTools.take(6).toList();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: filteredTools.length,
                      itemBuilder: (context, index) {
                        final tool = filteredTools[index];
                        return _buildUtilityCard(context, tool);
                      },
                    ),
                    if (_searchQuery.isEmpty && tools.length > 6)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showAllTools = !_showAllTools;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(4, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              _showAllTools ? 'View Less' : 'View More',
                              style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                  
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: BannerAdWidget(),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: NeoCard(
        backgroundColor: const Color(0xFFFF9800), // A bright orange
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        borderRadius: 12,
        shadowOffset: const Offset(4, 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 18),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Product',
                        style: AppTextStyles.heroTitle.copyWith(fontSize: 22, color: Colors.black),
                      ),
                      Text(
                        'ivity',
                        style: AppTextStyles.logoText.copyWith(fontSize: 22, color: Colors.black, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  Text(
                    'SUPERCHARGE YOUR WORK',
                    style: AppTextStyles.caption.copyWith(fontSize: 9, letterSpacing: 2, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search productivity tools...',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurface),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildUtilityCard(BuildContext context, Map<String, dynamic> tool) {
    final cardColor = tool['color'] as Color;

    return UniversalToolCard(
      title: tool['title'] as String,
      subtitle: tool['subtitle'] as String?,
      color: cardColor,
      icon: tool['icon'] as IconData,
      actionText: tool['actionText'] as String,
      onTap: () => _navigateToTool(context, tool),
    );
  }
}
