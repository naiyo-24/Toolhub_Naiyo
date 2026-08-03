import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import 'models/calendar_event.dart';

class CalendarService {
  static const String _eventsKey = 'calendar_events';
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (rootNavigatorKey.currentContext != null) {
          rootNavigatorKey.currentContext!.go('/calendar');
        }
      },
    );

    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  Future<List<CalendarEvent>> getEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getStringList(_eventsKey) ?? [];
    return eventsJson.map((e) => CalendarEvent.fromJson(e)).toList();
  }

  Future<void> saveEvents(List<CalendarEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = events.map((e) => e.toJson()).toList();
    await prefs.setStringList(_eventsKey, eventsJson);
  }

  Future<void> scheduleNotification(CalendarEvent event) async {
    if (!event.hasReminder) return;

    // Check if time has already passed
    if (event.dateTime.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id: event.id.hashCode,
      title: event.title,
      body: event.description,
      scheduledDate: tz.TZDateTime.from(event.dateTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'calendar_reminders_v2',
          'Calendar Reminders',
          channelDescription: 'Notifications for calendar events',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('universfield_ringtone'),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(String id) async {
    await _notificationsPlugin.cancel(id: id.hashCode);
  }
}
