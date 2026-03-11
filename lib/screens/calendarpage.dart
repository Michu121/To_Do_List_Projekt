import 'package:flutter/material.dart';
import 'package:todo_list/assets/widgets.dart';
class CalendarPage extends StatefulWidget{
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}
class _CalendarPageState extends State<CalendarPage>{
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text("Calendar"),
    );
  }
}