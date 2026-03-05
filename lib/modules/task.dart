import 'package:flutter/material.dart';

class Task{
  final int id;
  final String title;
  final bool isDone;
  final DateTime date;
  final TimeOfDay timeStart;
  final TimeOfDay timeEnd;

  Task({required this.id, required this.title, required this.isDone, required this.date,this.timeStart = const TimeOfDay(hour: 0, minute: 0),this.timeEnd = const TimeOfDay(hour: 0, minute: 0)});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      isDone: json['isDone'],
      date: DateTime.parse(json['date']),
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
  Map<String, dynamic> toJson(){
    return  {
      "id": id,
      "title": title,
      "isDone": isDone,
      "date": formatDate(date),
      "timeStart":{
        "hour": timeStart.hour,
        "minute": timeStart.minute
      },
      "timeEnd":{
        "hour": timeEnd.hour,
        "minute": timeEnd.minute
      },
    };
  }
  Task copyWith({
    int? id,
    String? title,
    bool? isDone,
    DateTime? date,
    TimeOfDay? timeStart,
    TimeOfDay? timeEnd
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      date: _validateDate(date??this.date),
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
    );
  }
  DateTime _validateDate(DateTime date){
    if(date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))){
      return DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    }else{
      return DateTime(date.year, date.month, date.day);
    }
  }
  String formatDate(DateTime date) {
    String m = date.month.toString().padLeft(2, '0');
    String d = date.day.toString().padLeft(2, '0');
    return "${date.year}-$m-$d";
  }
}