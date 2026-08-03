import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/calendar_service.dart';
import '../../data/models/calendar_event.dart';

final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

final calendarEventsProvider = StateNotifierProvider<CalendarEventsNotifier, List<CalendarEvent>>((ref) {
  return CalendarEventsNotifier(ref.watch(calendarServiceProvider));
});

class CalendarEventsNotifier extends StateNotifier<List<CalendarEvent>> {
  final CalendarService _calendarService;

  CalendarEventsNotifier(this._calendarService) : super([]) {
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    await _calendarService.init();
    state = await _calendarService.getEvents();
  }

  Future<void> addEvent(CalendarEvent event) async {
    final newState = [...state, event];
    state = newState;
    await _calendarService.saveEvents(newState);
    if (event.hasReminder) {
      await _calendarService.scheduleNotification(event);
    }
  }

  Future<void> removeEvent(String id) async {
    final newState = state.where((e) => e.id != id).toList();
    state = newState;
    await _calendarService.saveEvents(newState);
    await _calendarService.cancelNotification(id);
  }

  List<CalendarEvent> getEventsForDay(DateTime day) {
    return state.where((event) =>
      event.dateTime.year == day.year &&
      event.dateTime.month == day.month &&
      event.dateTime.day == day.day
    ).toList();
  }
}
