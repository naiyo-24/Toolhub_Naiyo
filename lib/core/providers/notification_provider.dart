import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }
}

class NotificationNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationNotifier() : super([]) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notifsJson = prefs.getString('app_notifications');
    final bool isFirstLaunch = prefs.getBool('has_launched_notifications') ?? false;

    if (notifsJson != null) {
      final List<dynamic> decoded = jsonDecode(notifsJson);
      state = decoded.map((item) => NotificationItem.fromJson(item)).toList();
    }

    if (!isFirstLaunch) {
      addNotification(
        'Welcome to Toolhub!',
        'Explore our collection of tools. Start by marking your favorites!',
      );
      await prefs.setBool('has_launched_notifications', true);
    }
  }

  Future<void> _saveNotifications(List<NotificationItem> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(notifications.map((e) => e.toJson()).toList());
    await prefs.setString('app_notifications', encoded);
  }

  void addNotification(String title, String message) {
    final newItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    final updatedList = [newItem, ...state];
    state = updatedList;
    _saveNotifications(updatedList);
  }

  void markAsRead(String id) {
    final updatedList = state.map((item) {
      if (item.id == id && !item.isRead) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
    
    state = updatedList;
    _saveNotifications(updatedList);
  }

  void markAllAsRead() {
    final updatedList = state.map((item) => item.copyWith(isRead: true)).toList();
    state = updatedList;
    _saveNotifications(updatedList);
  }

  void clearAll() {
    state = [];
    _saveNotifications([]);
  }

  int get unreadCount => state.where((item) => !item.isRead).length;
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<NotificationItem>>((ref) {
  return NotificationNotifier();
});
