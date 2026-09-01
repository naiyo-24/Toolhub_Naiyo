import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/widgets/universal_tool_card.dart';
import 'package:tool_hub/core/ads/banner_ad_widget.dart';


class HealthLifestyleScreen extends StatefulWidget {
  const HealthLifestyleScreen({super.key});

  static final List<Map<String, dynamic>> tools = [
      {'title': 'BMI Calculator', 'subtitle': 'Calculate your BMI', 'icon': Icons.monitor_weight_rounded, 'color': AppColors.primaryPink, 'actionText': 'Calculate', 'endpoint': '/bmi-calculator', 'config': [
        {'key': 'weight_kg', 'label': 'Weight (kg)', 'icon': Icons.scale, 'type': 'number'},
        {'key': 'height_cm', 'label': 'Height (cm)', 'icon': Icons.height, 'type': 'number'}
      ]},
      {'title': 'Water Reminder', 'subtitle': 'Track water intake', 'icon': Icons.water_drop_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Set Reminder', 'endpoint': '/water-tracker', 'config': [
        {'key': 'amount_ml', 'label': 'Amount of water (ml)', 'icon': Icons.local_drink, 'type': 'number'},
        {'key': 'reminder_type', 'label': 'Remind me', 'icon': Icons.notifications, 'type': 'dropdown', 'options': ['At Specific Time', 'After 30 mins', 'After 1 hour', 'After 1 hr 30 mins', 'After 2 hours']},
        {'key': 'specific_time', 'label': 'Time (if Specific Time)', 'icon': Icons.access_time, 'type': 'timepicker'}
      ]},
      {'title': 'Medicine Alert', 'subtitle': 'Medication reminder', 'icon': Icons.medication_rounded, 'color': AppColors.primaryRed, 'actionText': 'Track', 'endpoint': '/medicine-alert', 'config': [
        {'key': 'medication_name', 'label': 'Medication Name', 'icon': Icons.medication},
        {'key': 'dosage', 'label': 'Dosage (e.g. 1 pill, 500mg)', 'icon': Icons.healing},
        {'key': 'time_to_take', 'label': 'Time to take (HH:MM:SS)', 'icon': Icons.access_time, 'type': 'timepicker'}
      ]},
      {'title': 'Calorie Calc', 'subtitle': 'Count your calories', 'icon': Icons.restaurant_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Calculate', 'endpoint': '/calorie-calc', 'config': [
        {'key': 'meal_name', 'label': 'Meal Name', 'icon': Icons.fastfood},
        {'key': 'calories', 'label': 'Calories Consumed', 'icon': Icons.local_fire_department, 'type': 'number'}
      ]},
      {'title': 'Step Counter', 'subtitle': 'Track your steps', 'icon': Icons.directions_walk_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Sync Steps', 'endpoint': '/step-counter', 'config': [
        {'key': 'steps', 'label': 'Live Step Tracking', 'icon': Icons.directions_walk, 'type': 'live_pedometer'}
      ]},
      {'title': 'Sleep Tracker', 'subtitle': 'Monitor your sleep', 'icon': Icons.bed_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Track', 'endpoint': '/sleep-tracker', 'config': [
        {'key': 'hours_slept', 'label': 'Hours Slept', 'icon': Icons.bedtime, 'type': 'number'},
        {'key': 'quality', 'label': 'Sleep Quality', 'icon': Icons.star_rate, 'type': 'dropdown', 'options': ['Good', 'Fair', 'Poor']}
      ]},
      {'title': 'Period Tracker', 'subtitle': 'Track your cycle', 'icon': Icons.calendar_month_rounded, 'color': AppColors.primaryPink, 'actionText': 'Track', 'endpoint': '/period-tracker', 'config': [
        {'key': 'start_date', 'label': 'Start Date (YYYY-MM-DD)', 'icon': Icons.calendar_today, 'type': 'datepicker'},
        {'key': 'end_date', 'label': 'End Date (Optional, YYYY-MM-DD)', 'icon': Icons.event_busy, 'type': 'datepicker'},
        {'key': 'symptoms', 'label': 'Symptoms (Optional)', 'icon': Icons.sick}
      ]},
      {'title': 'Habit Tracker', 'subtitle': 'Daily habit tracking', 'icon': Icons.done_all_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Track', 'endpoint': '/habit-tracker', 'config': [
        {'key': 'habit_name', 'label': 'Name of the Habit', 'icon': Icons.track_changes}
      ]},
  ];

  @override
  State<HealthLifestyleScreen> createState() => _HealthLifestyleScreenState();
}

class _HealthLifestyleScreenState extends State<HealthLifestyleScreen> {
  String _searchQuery = '';
  bool _showAllTools = false;

  @override
  Widget build(BuildContext context) {
    var filteredTools = HealthLifestyleScreen.tools.where((tool) {
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
                    if (_searchQuery.isEmpty && HealthLifestyleScreen.tools.length > 6)
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
        backgroundColor: const Color(0xFF00C853), // A vibrant green
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Health & ',
                          style: AppTextStyles.heroTitle.copyWith(fontSize: 22, color: Colors.black),
                        ),
                        Text(
                          'Lifestyle',
                          style: AppTextStyles.logoText.copyWith(fontSize: 22, color: Colors.black, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'LIVE YOUR BEST LIFE',
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
            hintText: 'Search health tools...',
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
      onTap: () {
        if (tool['title'] == 'BMI Calculator') {
          context.push('/bmi-calculator');
        } else {
          context.push('/health-lifestyle/tool', extra: tool);
        }
      },
    );
  }
}
