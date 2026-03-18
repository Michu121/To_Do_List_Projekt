import 'package:flutter/material.dart';

enum Difficulty {
  easy(
    value: 0,
    label: 'Easy',
    points: 10,
    color: Colors.green,
    icon: Icons.sentiment_satisfied_alt,
  ),
  medium(
    value: 1,
    label: 'Medium',
    points: 25,
    color: Colors.orange,
    icon: Icons.sentiment_neutral,
  ),
  hard(
    value: 2,
    label: 'Hard',
    points: 50,
    color: Colors.red,
    icon: Icons.local_fire_department,
  );

  final int value;
  final String label;
  final int points;
  final Color color;
  final IconData icon;

  const Difficulty({
    required this.value,
    required this.label,
    required this.points,
    required this.color,
    required this.icon,
  });

  static Difficulty fromInt(int v) =>
      Difficulty.values.firstWhere((e) => e.value == v, orElse: () => Difficulty.easy);

  int toInt() => value;
}
