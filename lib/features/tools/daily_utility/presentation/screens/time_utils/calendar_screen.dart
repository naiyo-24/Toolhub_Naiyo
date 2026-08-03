import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../../../data/models/calendar_event.dart';
import '../../providers/calendar_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    bool setReminder = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
              title: const Text('New Event', style: AppTextStyles.sectionTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.black, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.black, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Time: ${selectedTime.format(context)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.access_time, color: Colors.black),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                          builder: (context, child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                              child: Center(
                                child: SingleChildScrollView(
                                  child: child,
                                ),
                              ),
                            );
                          },
                        );
                        if (time != null) {
                          setState(() => selectedTime = time);
                        }
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Set Reminder Notification', style: TextStyle(fontWeight: FontWeight.bold)),
                      value: setReminder,
                      activeThumbColor: AppColors.primaryGreen,
                      onChanged: (val) => setState(() => setReminder = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;

                    final eventDate = DateTime(
                      _selectedDay!.year,
                      _selectedDay!.month,
                      _selectedDay!.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    final event = CalendarEvent(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      dateTime: eventDate,
                      hasReminder: setReminder,
                    );

                    ref.read(calendarEventsProvider.notifier).addEvent(event);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(calendarEventsProvider);
    final selectedEvents = _selectedDay != null
        ? ref.read(calendarEventsProvider.notifier).getEventsForDay(_selectedDay!)
        : <CalendarEvent>[];

    // Sort events by time
    selectedEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Calendar & Events',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box, color: Colors.white, size: 30),
            onPressed: _showAddEventDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
            child: TableCalendar<CalendarEvent>(
              rowHeight: 46, // Makes the calendar more compact vertically
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'SpaceGrotesk'),
                leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primaryBlack, size: 30),
                rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primaryBlack, size: 30),
                headerPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              eventLoader: (day) {
                return ref.read(calendarEventsProvider.notifier).getEventsForDay(day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              calendarStyle: const CalendarStyle(
                defaultTextStyle: TextStyle(fontWeight: FontWeight.w600),
                weekendTextStyle: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                outsideDaysVisible: false,
                selectedDecoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                markerDecoration: BoxDecoration(
                  color: AppColors.primaryPink,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                cellMargin: EdgeInsets.all(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Text(
                  _selectedDay != null ? DateFormat('EEEE, MMM d').format(_selectedDay!) : 'Agenda',
                  style: AppTextStyles.sectionTitle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: selectedEvents.isEmpty
                ? const Center(
                    child: Text(
                      'No events scheduled for this day.',
                      style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: selectedEvents.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      return NeoCard(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('hh:mm a').format(event.dateTime),
                                  style: AppTextStyles.sectionTitle.copyWith(color: AppColors.primaryGreen, fontSize: 18),
                                ),
                                if (event.hasReminder)
                                  const Icon(Icons.notifications_active, size: 16, color: AppColors.primaryPink),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Container(width: 2, height: 40, color: Colors.black12),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  if (event.description.isNotEmpty)
                                    Text(event.description, style: const TextStyle(color: Colors.black54)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                ref.read(calendarEventsProvider.notifier).removeEvent(event.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
