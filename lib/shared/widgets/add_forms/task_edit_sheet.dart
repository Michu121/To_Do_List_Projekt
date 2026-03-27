import 'dart:async';

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

import '../../models/category.dart';
import '../../models/colors.dart';
import '../../models/difficulty.dart';
import '../../models/group.dart';
import '../../models/status.dart';
import '../../models/task.dart';
import '../../services/category_services.dart';
import '../../services/color_services.dart';
import '../../services/group_task_service.dart';
import '../../services/notification_service.dart';
import '../../services/task_services.dart';
import '../pickers/color_picker.dart';
import 'package:todo_list/app_settings.dart' show AppSettings;

class TaskEditSheet extends StatefulWidget {
  const TaskEditSheet({
    super.key,
    required this.task,
    this.showGroupPicker = true,
  });

  final Task task;
  final bool showGroupPicker;

  static void show(
      BuildContext context, {
        required Task task,
        bool showGroupPicker = true,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => TaskEditSheet(
        task: task,
        showGroupPicker: showGroupPicker,
      ),
    );
  }

  @override
  State<TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<TaskEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  final _colorServices = ColorServices();

  late final List<Group> _groups;
  late Category? _selectedCategory;
  late Difficulty _selectedDifficulty;
  late ColorsToPick? _selectedColor;
  late Group? _selectedGroup;
  late DateTime _selectedDate;
  late TimeOfDay? _timeStart;
  late TimeOfDay? _timeEnd;
  late Status _selectedStatus;

  @override
  void initState() {
    super.initState();
    final task = widget.task;

    _titleController = TextEditingController(text: task.title);
    _descController = TextEditingController(text: task.description);

    _groups = [
      Group(name: '🚫 None', color: Colors.grey.shade300),
      ...groupTaskService.groups,
    ];

    _selectedCategory = task.category;
    _selectedDifficulty = task.difficulty;
    _selectedDate = task.date;
    _selectedStatus = task.status;

    // Pre-select the task's existing color in the picker
    final matchedKey = _colorServices
        .getColors()
        .entries
        .where((e) => e.value.color.toARGB32() == task.color.toARGB32())
        .map((e) => e.key)
        .firstOrNull;
    if (matchedKey != null) {
      _colorServices.updateColor(matchedKey, true);
    }
    _selectedColor = _colorServices.getColors().values.firstOrNull;

    // Group
    if (task.group != null) {
      try {
        _selectedGroup = _groups.firstWhere((g) => g.id == task.group!.id);
      } catch (_) {
        _selectedGroup = _groups.first;
      }
    } else {
      _selectedGroup = _groups.first;
    }

    _timeStart = task.timeStart.hour == 0 && task.timeStart.minute == 0
        ? null
        : task.timeStart;
    _timeEnd =
    task.timeEnd.hour == 0 && task.timeEnd.minute == 0 ? null : task.timeEnd;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_timeStart ?? TimeOfDay.now())
        : (_timeEnd ?? TimeOfDay.now());
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _timeStart = picked;
        } else {
          _timeEnd = picked;
        }
      });
    }
  }

  bool get _isPersonalTask => _selectedGroup == _groups.first;

  void _handleSave() {
    final titleText = _titleController.text.trim();
    if (titleText.isEmpty) return;

    final updated = widget.task.copyWith(
      title: titleText,
      description: _descController.text,
      category: _selectedCategory ?? widget.task.category,
      difficulty: _selectedDifficulty,
      color: _selectedColor?.color ?? widget.task.color,
      date: _selectedDate,
      status: _selectedStatus,
      group: widget.showGroupPicker
          ? (_isPersonalTask ? null : _selectedGroup)
          : widget.task.group,
      timeStart: _timeStart ?? const TimeOfDay(hour: 0, minute: 0),
      timeEnd: _timeEnd ?? const TimeOfDay(hour: 0, minute: 0),
    );

    Navigator.of(context).pop();

    final groupId = widget.task.group?.id;
    if (groupId != null) {
      groupTaskService.updateTask(groupId, updated);
    } else {
      unawaited(taskServices.updateTask(updated));
    }

    // Re-schedule notification
    notificationService.cancelNotification(updated.id);
    if (AppSettings.instance.notificationsEnabled && _timeStart != null) {
      final taskDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _timeStart!.hour,
        _timeStart!.minute,
      );
      notificationService.scheduleTaskNotification(
        taskId: updated.id,
        title: updated.title,
        taskDateTime: taskDateTime,
        minutesBefore: AppSettings.instance.notificationMinutesBefore,
      );
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Returns the translated difficulty label.
  String _difficultyLabel(Difficulty d, AppLocalizations? t) {
    switch (d) {
      case Difficulty.easy:
        return t?.easy ?? d.label;
      case Difficulty.medium:
        return t?.medium ?? d.label;
      case Difficulty.hard:
        return t?.hard ?? d.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final t = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle + title ──────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    t?.editTask ?? 'Edit Task',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // Status chip
                _StatusChip(
                  status: _selectedStatus,
                  onChanged: (s) => setState(() => _selectedStatus = s),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Title ───────────────────────────────────────────────
            TextField(
              controller: _titleController,
              autofocus: false,
              decoration: InputDecoration(
                labelText: t?.title ?? 'Title',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _handleSave(),
            ),
            const SizedBox(height: 10),

            // ── Description ─────────────────────────────────────────
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: t?.description ?? 'Description',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Date + Time ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    icon: Icons.calendar_today_outlined,
                    label: _formatDate(_selectedDate),
                    onTap: _pickDate,
                    accent: accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.access_time,
                    label: _timeStart != null
                        ? _formatTime(_timeStart!)
                        : (t?.startTime ?? 'Start time'),
                    onTap: () => _pickTime(isStart: true),
                    accent: accent,
                    faded: _timeStart == null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.timer_outlined,
                    label: _timeEnd != null
                        ? _formatTime(_timeEnd!)
                        : (t?.endTime ?? 'End time'),
                    onTap: () => _pickTime(isStart: false),
                    accent: accent,
                    faded: _timeEnd == null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Difficulty ──────────────────────────────────────────
            _DifficultyPicker(
              selected: _selectedDifficulty,
              label: t?.difficulty ?? 'Difficulty',
              onChanged: (d) => setState(() => _selectedDifficulty = d),
              difficultyLabel: (d) => _difficultyLabel(d, t),
            ),
            const SizedBox(height: 14),

            // ── Category ────────────────────────────────────────────
            _SectionLabel(t?.category ?? 'Category', accent),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: categoryServices,
              builder: (context, _) {
                final cats = categoryServices.getCategories().values.toList();
                return _ChipRow(
                  children: cats.map((cat) {
                    // Compare by id (stable) so selection survives locale change
                    final sel = _selectedCategory?.id == cat.id ||
                        _selectedCategory?.name == cat.name;
                    return _InlineChip(
                      label: cat.name,
                      color: cat.color,
                      selected: sel,
                      onTap: () => setState(() => _selectedCategory = cat),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Color ───────────────────────────────────────────────
            _SectionLabel(t?.taskColor ?? 'Task color', accent),
            const SizedBox(height: 6),
            ColorPicker(
              colorServices: _colorServices,
              selectedColor: _selectedColor,
              onTap: (name) {
                setState(() {
                  _colorServices.updateColor(name, true);
                  _selectedColor = _colorServices.getColors()[name];
                });
              },
            ),
            const SizedBox(height: 20),

            // ── Save ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _handleSave,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  t?.saveChanges ?? 'Save Changes',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.accent);
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

// ── Chip row ──────────────────────────────────────────────────────────────────

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) => children[i],
      ),
    );
  }
}

// ── Inline chip ───────────────────────────────────────────────────────────────

class _InlineChip extends StatelessWidget {
  const _InlineChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? (color.computeLuminance() > 0.45 ? Colors.black87 : Colors.white)
        : color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.4),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: selected ? fg.withValues(alpha: 0.8) : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.onChanged});
  final Status status;
  final ValueChanged<Status> onChanged;

  Status get _next => switch (status) {
    Status.todo => Status.inProgress,
    Status.inProgress => Status.done,
    Status.done => Status.todo,
  };

  String _label(AppLocalizations? t, BuildContext context) { // Add context here
    switch (status) {
      case Status.todo:
        return t?.todo ?? status.label(context);
      case Status.inProgress:
        return t?.inProgress ?? status.label(context);
      case Status.done:
        return t?.done ?? status.label(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => onChanged(_next),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: status.color),
          const SizedBox(width: 4),
          Expanded(
            child: Center(
              child: Text(
                _label(t, context), // Pass 'context' here
                style: TextStyle(
                  fontSize: 12,
                  color: status.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ── Difficulty picker ─────────────────────────────────────────────────────────

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({
    required this.selected,
    required this.label,
    required this.onChanged,
    required this.difficultyLabel,
  });

  final Difficulty selected;
  final String label;
  final ValueChanged<Difficulty> onChanged;
  final String Function(Difficulty) difficultyLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final diff in Difficulty.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: GestureDetector(
                    onTap: () => onChanged(diff),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected == diff
                            ? diff.color.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected == diff
                              ? diff.color
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(diff.icon, color: diff.color, size: 20),
                          const SizedBox(height: 2),
                          Text(
                            difficultyLabel(diff),
                            style: TextStyle(
                              fontSize: 10,
                              color: diff.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '+${diff.points}pts',
                            style: TextStyle(fontSize: 9, color: diff.color),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Picker button ─────────────────────────────────────────────────────────────

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accent,
    this.faded = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accent;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: faded ? theme.dividerColor : accent.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(10),
          color: faded ? Colors.transparent : accent.withValues(alpha: 0.06),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: faded ? Colors.grey : accent,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: faded ? Colors.grey.shade500 : accent,
                  fontWeight: faded ? FontWeight.normal : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}