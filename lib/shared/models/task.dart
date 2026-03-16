import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'status.dart';
import 'category.dart';
import 'group.dart';

const uuid = Uuid();

class Task {

  final String id;
  final String title;
  final Category category;
  final Group? group;
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
    required this.description,
    required this.date,
    this.group,
    this.color = Colors.grey,
    this.timeStart = const TimeOfDay(hour: 0, minute: 0),
    this.timeEnd = const TimeOfDay(hour: 0, minute: 0),
  }) : id = id ?? uuid.v4();

  factory Task.fromJson(Map<String, dynamic> json) {

    return Task(
      id: json['id'],
      title: json['title'],

      status: Status.fromInt(json['status']),

      category: Category.fromJson(json['category']),

      group: json['group'] != null
          ? Group.fromJson(json['group'])
          : null,

      description: json['description'],

      date: DateTime.parse(json['date']),

      color: Color(json['color']),

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
      "status": status.toInt(),

      "category": category.toJson(),

      "group": group?.toJson(),

      "description": description,

      "date": date.toIso8601String(),

      "color": color.value,

      "timeStart": {
        "hour": timeStart.hour,
        "minute": timeStart.minute
      },

      "timeEnd": {
        "hour": timeEnd.hour,
        "minute": timeEnd.minute
      }
    };
  }
}