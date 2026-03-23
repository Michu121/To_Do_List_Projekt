// lib/shared/widgets/task_tiles/task_chip.dart
//
// Small coloured pill used on task tiles to label category and group.
// Extracted from homepage.dart (_Chip) and replaces the old _CategoryChip
// that was in the broken task_list_tile.dart.
//
// USAGE:
//   TaskChip(label: task.category.name, color: task.category.color)
//   TaskChip(label: task.group!.name,   color: task.group!.color, icon: Icons.group)

import 'package:flutter/material.dart';

class TaskChip extends StatelessWidget {
  const TaskChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
