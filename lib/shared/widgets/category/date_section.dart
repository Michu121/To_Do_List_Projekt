// lib/shared/widgets/category/date_section.dart
//
// Groups a list of tasks under a formatted date header.
// Extracted from homepage.dart (_DateSection + _Section).

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/task.dart';
import '../task_tiles/task_list_tile.dart';

// ── Data model ────────────────────────────────────────────────────────────────

/// Simple data holder: one date bucket → list of tasks.
class TaskSection {
  final String label; // raw "YYYY-M-D" key, formatted by DateSection
  final List<Task> tasks;
  TaskSection({required this.label, required this.tasks});
}

// ── Widget ────────────────────────────────────────────────────────────────────

class DateSection extends StatelessWidget {
  const DateSection({
    super.key,
    required this.label,
    required this.tasks,
  });

  final String label; // raw "YYYY-M-D" key
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(
            _formatLabel(label, context),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.7),
            ),
          ),
        ),
        ...tasks.map((t) => TaskListTile(task: t, disabled: false)),
      ],
    );
  }

  /// Converts "2025-3-8" → "TODAY" / "TOMORROW" / "8 MAR 2025".
  String _formatLabel(String isoKey, BuildContext context) {
    final t = AppLocalizations.of(context);
    final parts = isoKey.split('-');
    if (parts.length != 3) return isoKey;

    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (date == today) return t?.today ?? 'TODAY';
    if (date == tomorrow) return t?.tomorrow ?? 'TOMORROW';

    final months = [
      t?.january ?? 'JAN',
      t?.february ?? 'FEB',
      t?.march ?? 'MAR',
      t?.april ?? 'APR',
      t?.may ?? 'MAY',
      t?.june ?? 'JUN',
      t?.july ?? 'JUL',
      t?.august ?? 'AUG',
      t?.september ?? 'SEP',
      t?.october ?? 'OCT',
      t?.november ?? 'NOV',
      t?.december ?? 'DEC',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ── Helper to build sections from a flat task list ────────────────────────────

/// Groups [tasks] by date and returns sorted [TaskSection] list.
/// Pure function — no Flutter imports needed beyond the model.
List<TaskSection> groupTasksByDate(List<Task> tasks) {
  final map = <String, List<Task>>{};
  for (final task in tasks) {
    final key =
        '${task.date.year}-${task.date.month}-${task.date.day}';
    map.putIfAbsent(key, () => []).add(task);
  }
  final keys = map.keys.toList()..sort();
  return keys
      .map((k) => TaskSection(label: k, tasks: map[k]!))
      .toList();
}
