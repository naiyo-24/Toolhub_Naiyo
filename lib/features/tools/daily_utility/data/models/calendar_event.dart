import 'dart:convert';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final bool hasReminder;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.hasReminder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'hasReminder': hasReminder,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dateTime: DateTime.parse(map['dateTime']),
      hasReminder: map['hasReminder'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory CalendarEvent.fromJson(String source) =>
      CalendarEvent.fromMap(json.decode(source));
}
