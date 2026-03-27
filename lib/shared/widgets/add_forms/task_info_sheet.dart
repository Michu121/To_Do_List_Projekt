import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

import '../../models/status.dart';
import '../../models/task.dart';

class TaskInfoSheet extends StatelessWidget {
  const TaskInfoSheet({super.key, required this.task});

  final Task task;

  static void show(BuildContext context, {required Task task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => TaskInfoSheet(task: task),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final onAccent = accent.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;
    final t = AppLocalizations.of(context);

    final hasStartTime = task.timeStart.hour != 0 || task.timeStart.minute != 0;
    final hasEndTime = task.timeEnd.hour != 0 || task.timeEnd.minute != 0;

    final categoryName = task.category.id == 'default'
        ? (t?.defaultCategory ?? task.category.name)
        : task.category.name;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Coloured header ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: onAccent.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: onAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Task Info',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: onAccent)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: task.status.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(task.status.icon, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(task.status.label(context),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ──────────────────────────────────
                    _InfoSection(
                      icon: Icons.title,
                      label: t?.title ?? 'Title',
                      accent: accent,
                      child: Text(
                        task.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Description ────────────────────────────
                    if (task.description.isNotEmpty) ...[
                      _InfoSection(
                        icon: Icons.notes,
                        label: t?.description ?? 'Description',
                        accent: accent,
                        child: Text(
                          task.description,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Category ───────────────────────────────
                    _InfoSection(
                      icon: Icons.category,
                      label: t?.category ?? 'Category',
                      accent: accent,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: task.category.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: task.category.color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: task.category.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              categoryName,
                              style: TextStyle(
                                  color: task.category.color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Difficulty ─────────────────────────────
                    _InfoSection(
                      icon: Icons.flash_on,
                      label: t?.difficulty ?? 'Difficulty',
                      accent: accent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(task.difficulty.icon,
                              color: task.difficulty.color, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            task.difficulty.label,
                            style: TextStyle(
                                color: task.difficulty.color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: task.difficulty.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${task.difficulty.points}pts',
                              style: TextStyle(
                                  color: task.difficulty.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Date ───────────────────────────────────
                    _InfoSection(
                      icon: Icons.calendar_today_outlined,
                      label: t?.date ?? 'Date',
                      accent: accent,
                      child: Text(
                        _formatDate(task.date),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Time ───────────────────────────────────
                    if (hasStartTime || hasEndTime) ...[
                      _InfoSection(
                        icon: Icons.schedule,
                        label: t?.time ?? 'Time',
                        accent: accent,
                        child: Row(
                          children: [
                            if (hasStartTime) ...[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t?.startTime ?? 'Start',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600),
                                    ),
                                    Text(
                                      _formatTime(task.timeStart),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (hasEndTime) ...[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t?.endTime ?? 'End',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600),
                                    ),
                                    Text(
                                      _formatTime(task.timeEnd),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Group ──────────────────────────────────
                    if (task.group != null) ...[
                      _InfoSection(
                        icon: Icons.group,
                        label: t?.group ?? 'Group',
                        accent: accent,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: task.group!.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: task.group!.color.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.group, size: 14, color: task.group!.color),
                              const SizedBox(width: 6),
                              Text(
                                task.group!.name,
                                style: TextStyle(
                                    color: task.group!.color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Color ──────────────────────────────────
                    _InfoSection(
                      icon: Icons.palette,
                      label: t?.color ?? 'Color',
                      accent: accent,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: task.color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.dividerColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Section Widget ──────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.icon,
    required this.label,
    required this.accent,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: child,
        ),
      ],
    );
  }
}
