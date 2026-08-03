import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

String formatTimeAgo(DateTime date) {
  final duration = DateTime.now().difference(date);
  if (duration.inDays > 7) return '${date.day}/${date.month}/${date.year}';
  if (duration.inDays > 0) return '${duration.inDays}d ago';
  if (duration.inHours > 0) return '${duration.inHours}h ago';
  if (duration.inMinutes > 0) return '${duration.inMinutes}m ago';
  return 'Just now';
}

class HistoryItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final DateTime timestamp;

  HistoryItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'bgColor': bgColor.toARGB32(),
      'iconColor': iconColor.toARGB32(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      title: json['title'],
      subtitle: json['subtitle'],
      icon: IconData(
        // ignore: non_const_argument_for_const_parameter
        json['iconCodePoint'],
        // ignore: non_const_argument_for_const_parameter
        fontFamily: json['iconFontFamily'],
      ),
      bgColor: Color(json['bgColor']),
      iconColor: Color(json['iconColor']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class HistoryNotifier extends StateNotifier<List<HistoryItem>> {
  HistoryNotifier() : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('recently_used_tools');
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      state = decoded.map((item) => HistoryItem.fromJson(item)).toList();
    }
  }

  Future<void> _saveHistory(List<HistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString('recently_used_tools', encoded);
  }

  void addToolToHistory(String title, String subtitle, IconData icon, Color bgColor, Color iconColor) {
    final newItem = HistoryItem(
      title: title,
      subtitle: subtitle,
      icon: icon,
      bgColor: bgColor,
      iconColor: iconColor,
      timestamp: DateTime.now(),
    );

    // Remove if it already exists to move it to the top
    var updatedList = state.where((item) => item.title != title).toList();
    
    // Insert at beginning
    updatedList.insert(0, newItem);

    // Keep only last 20
    if (updatedList.length > 20) {
      updatedList = updatedList.sublist(0, 20);
    }

    state = updatedList;
    _saveHistory(updatedList);
  }

  void clearHistory() {
    state = [];
    _saveHistory([]);
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, List<HistoryItem>>((ref) {
  return HistoryNotifier();
});
