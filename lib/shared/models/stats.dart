import 'package:flutter/material.dart';

enum Stats {

  streak(
    label: "Streak",
    icon: Icons.star,
    color: Colors.red,
  ),
  doneTask(
    label: "Done tasks",
    icon: Icons.task_alt,
    color: Colors.green,
  ),
  todoTask(
    label: "To do tasks",
    icon: Icons.category,
    color: Colors.blue,
  );


  final String label;
  final IconData icon;
  final Color color;

  const Stats({
    required this.label,
    required this.icon,
    required this.color,
  });


}