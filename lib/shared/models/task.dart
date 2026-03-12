import 'package:flutter/material.dart';
import 'status.dart';
import 'category.dart';
import 'group.dart';
import 'package:uuid/uuid.dart';

Uuid uuid = const Uuid();

class Task {
  final String id;
  final String title;
  final Category category;
  final Group group;
  final String description;
  final Status status;
  final DateTime date;
  final Color color;
  final TimeOfDay timeStart;
  final TimeOfDay timeEnd;

  Task({
    String? id,
    required this.title,
    required this.status,
    required this.category,
    required this.group,
    required this.description,
    required this.date,
    this.color = Colors.grey,
    this.timeStart = const TimeOfDay(hour: 0, minute: 0),
    this.timeEnd = const TimeOfDay(hour: 0, minute: 0),
  }) : id = id ?? uuid.v4();

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? "Null",
      title: json['title'] ?? "Null",
      status: json['status'] ?? 0,
      date: DateTime.parse(json['date']??DateTime.now().toString()),
      category: json['category']??"Null",
      group: json['group'] ?? "Null",
      description: json['description']??"Null",
      color: Colors.grey,
      timeStart: TimeOfDay(
        hour: json['timeStart']['hour'],
        minute: json['timeStart']['minute'],
      ),
      timeEnd: TimeOfDay(
        hour: json['timeEnd']['hour'],
        minute: json['timeEnd']['minute'],
      ),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "status": status,
      "date": formatDate(date),
      "category": category,
      "group": group,
      "color": color, // Konwersja na wartość typu int"
      "description": description,
      "timeStart": {"hour": timeStart.hour, "minute": timeStart.minute},
      "timeEnd": {"hour": timeEnd.hour, "minute": timeEnd.minute},
    };
  }

  Task copyWith({
    String? title,
    Status? status,
    DateTime? date,
    Category? category,
    Group? group,
    String? description,
    Color? color,
    TimeOfDay? timeStart,
    TimeOfDay? timeEnd,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      status: status ?? this.status,
      date: _validateDate(date ?? this.date),
      category: category ?? this.category,
      group: group ?? this.group,
      description: description ?? this.description,
      color: color ?? this.color,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
    );
  }

  DateTime _validateDate(DateTime date) {
    if (date.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    )) {
      return DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
    } else {
      return DateTime(date.year, date.month, date.day);
    }
  }

  String formatDate(DateTime date) {
    String m = date.month.toString().padLeft(2, '0');
    String d = date.day.toString().padLeft(2, '0');
    return "${date.year}-$m-$d";
  }
}
