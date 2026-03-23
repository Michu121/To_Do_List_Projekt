import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'difficulty.dart';
import 'status.dart';
import 'category.dart';
import 'group.dart';

const _uuid = Uuid();

class Task {
  final String id;
  final String title;
  final Category category;
  final Group? group;
  final String description;
  final Difficulty difficulty;
  final Status status;
  final DateTime date;
  final Color color;
  final TimeOfDay timeStart;
  final TimeOfDay timeEnd;
  final bool isDeleted; // ← soft-delete flag

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
    required this.difficulty,
    this.isDeleted = false,
  }) : id = id ?? _uuid.v4();

  factory Task.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.parse(raw);
      return DateTime.now();
    }

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      status: Status.fromInt(json['status'] as int),
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      group: json['group'] != null
          ? Group.fromJson(json['group'] as Map<String, dynamic>)
          : null,
      description: json['description'] as String,
      date: parseDate(json['date']),
      color: Color(json['color'] as int),
      timeStart: TimeOfDay(
        hour: (json['timeStart'] as Map)['hour'] as int,
        minute: (json['timeStart'] as Map)['minute'] as int,
      ),
      timeEnd: TimeOfDay(
        hour: (json['timeEnd'] as Map)['hour'] as int,
        minute: (json['timeEnd'] as Map)['minute'] as int,
      ),
      difficulty: Difficulty.fromInt(json['difficulty'] as int),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status.toInt(),
      'category': category.toJson(),
      'group': group?.toJson(),
      'difficulty': difficulty.toInt(),
      'description': description,
      'date': date.toIso8601String(),
      'color': color.toARGB32(),
      'timeStart': {'hour': timeStart.hour, 'minute': timeStart.minute},
      'timeEnd': {'hour': timeEnd.hour, 'minute': timeEnd.minute},
      'isDeleted': isDeleted,
    };
  }

  Task copyWith({
    String? title,
    Status? status,
    DateTime? date,
    Category? category,
    Group? group,
    String? description,
    Difficulty? difficulty,
    Color? color,
    TimeOfDay? timeStart,
    TimeOfDay? timeEnd,
    bool? isDeleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      status: status ?? this.status,
      date: date ?? this.date,
      category: category ?? this.category,
      group: group ?? this.group,
      description: description ?? this.description,
      color: color ?? this.color,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      difficulty: difficulty ?? this.difficulty,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  String formatDate(DateTime d) => '${d.day}.${d.month}.${d.year}';
}