// lib/shared/widgets/task_tiles/difficulty_badge.dart
//
// Shows the difficulty icon and points next to a task title.
// Extracted from homepage.dart (_DifficultyBadge).

import 'package:flutter/material.dart';
import '../../models/task.dart';

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final d = task.difficulty;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(d.icon, size: 13, color: d.color),
        const SizedBox(width: 2),
        Text(
          '+${d.points}',
          style: TextStyle(
            fontSize: 11,
            color: d.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
