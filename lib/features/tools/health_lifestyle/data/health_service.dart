import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tool_hub/core/api/api_config.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tool_hub/core/utils/permission_disclosure_utils.dart';

class HealthService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> _initNotifications(BuildContext? context) async {
    if (_isInitialized) return;
    
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
    await _notificationsPlugin.initialize(settings: initializationSettings);
    
    if (context != null && context.mounted) {
      await PermissionDisclosureUtils.requestWithDisclosure(
        context,
        permission: Permission.notification,
        title: 'Notification Permission',
        description: 'We need permission to send you timely health, water, and medicine reminders.',
        icon: Icons.notifications_active_rounded,
        color: Colors.red,
      );
      
      await PermissionDisclosureUtils.requestWithDisclosure(
        // ignore: use_build_context_synchronously
        context,
        permission: Permission.scheduleExactAlarm,
        title: 'Exact Alarm Permission',
        description: 'To ensure your alarms ring precisely at the specified time even when the screen is locked, we need Exact Alarms permission.',
        icon: Icons.alarm_rounded,
        color: Colors.blue,
      );
    }
    
    _isInitialized = true;
  }

  Future<void> scheduleMedicineAlarm(BuildContext context, String name, String dosage, String timeStr) async {
    await _initNotifications(context);

    final parts = timeStr.split(':');
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year, now.month, now.day,
      int.parse(parts[0]), int.parse(parts[1]), 0,
    );
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: name.hashCode,
      title: 'Medicine Reminder: $name',
      body: 'Time to take your medication: $dosage',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_alerts_v5',
          'Medicine Alerts',
          channelDescription: 'Alarm notifications for taking medicines',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('universfield_ringtone'),
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleWaterAlarm(BuildContext context, String amount, String reminderType, String? specificTime) async {
    await _initNotifications(context);

    final now = DateTime.now();
    
    // First, cancel any previously set water alarms (we use up to 40 slots)
    for (int i = 0; i < 40; i++) {
      await _notificationsPlugin.cancel(id: 'water_reminder'.hashCode + i);
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'water_alerts_v2', // Bumped ID to ensure new properties take effect
        'Water Alerts',
        channelDescription: 'Alarm notifications for drinking water',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('universfield_ringtone'),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    if (reminderType == 'At Specific Time' && specificTime != null && specificTime.isNotEmpty) {
      final parts = specificTime.split(':');
      DateTime scheduledDate = DateTime(
        now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]), 0,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      await _notificationsPlugin.zonedSchedule(
        id: 'water_reminder'.hashCode,
        title: 'Water Reminder',
        body: 'Time to drink $amount ml of water!',
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      int minutesToAdd = 0;
      if (reminderType.contains('30 mins')) {
        minutesToAdd = 30;
      } else if (reminderType == 'After 1 hour') {
        minutesToAdd = 60;
      } else if (reminderType == 'After 1 hr 30 mins') {
        minutesToAdd = 90;
      } else if (reminderType == 'After 2 hours') {
        minutesToAdd = 120;
      } else {
        minutesToAdd = 30;
      }
      
      // Schedule the next 30 occurrences to cover the whole day automatically
      for (int i = 0; i < 30; i++) {
        final scheduledDate = now.add(Duration(minutes: minutesToAdd * (i + 1)));
        
        await _notificationsPlugin.zonedSchedule(
          id: 'water_reminder'.hashCode + i,
          title: 'Water Reminder',
          body: 'Time to drink $amount ml of water!',
          scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  Future<Map<String, dynamic>> calculate(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/health-tools$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to process request: $e');
    }
  }
  Future<void> cancelAllAlarms() async {
    await _initNotifications(null);
    await _notificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingAlarms() async {
    await _initNotifications(null);
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  Future<void> cancelAlarm(int id) async {
    await _initNotifications(null);
    await _notificationsPlugin.cancel(id: id);
  }
}
