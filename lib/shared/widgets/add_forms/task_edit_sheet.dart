import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/colors.dart';
import '../../models/difficulty.dart';
import '../../models/group.dart';
import '../../models/status.dart';
import '../../models/task.dart';
import '../../services/color_services.dart';
import '../../services/group_task_service.dart';
import '../../services/notification_service.dart';
import '../../services/task_services.dart';
import '../pickers/category_picker.dart';
import '../pickers/color_picker.dart';
import '../pickers/group_picker.dart';
import 'package:todo_list/app_settings.dart' show AppSettings;

class TaskEditSheet extends StatefulWidget {
  const TaskEditSheet({
    super.key,
    required this.task,
    this.showGroupPicker = true,
  });

  final Task task;

  /// When editing from a group detail, hide the group picker.
  final bool showGroupPicker;

  static void show(
      BuildContext context, {
        required Task task,
        bool showGroupPicker = true,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
  bool _enableNotification = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;

    _titleController = TextEditingController(text: t.title);
    _descController = TextEditingController(text: t.description);

    _groups = [
      Group(name: '🚫 None', color: Colors.grey.shade300),
      ...groupTaskService.groups,
    ];

    _selectedCategory = t.category;
    _selectedDifficulty = t.difficulty;
    _selectedDate = t.date;
    _selectedStatus = t.status;

    // Pre-select the task's existing color in the picker
    final matchedKey = _colorServices.getColors().entries
        .where((e) => e.value.color.toARGB32() == t.color.toARGB32())
        .map((e) => e.key)
        .firstOrNull;
    if (matchedKey != null) {
      _colorServices.updateColor(matchedKey, true);
    }
    _selectedColor = _colorServices.getColors().values.firstOrNull;

    // Group
    if (t.group != null) {
      try {
        _selectedGroup = _groups.firstWhere((g) => g.id == t.group!.id);
      } catch (_) {
        _selectedGroup = _groups.first;
      }
    } else {
      _selectedGroup = _groups.first;
    }

    _timeStart = t.timeStart.hour == 0 && t.timeStart.minute == 0
        ? null
        : t.timeStart;
    _timeEnd =
    t.timeEnd.hour == 0 && t.timeEnd.minute == 0 ? null : t.timeEnd;
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
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final updated = widget.task.copyWith(
      title: title,
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
    if (_enableNotification &&
        AppSettings.instance.notificationsEnabled &&
        _timeStart != null) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(20)),
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
                  child: Text('Edit Task',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface)),
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
                labelText: 'Title',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _handleSave(),
            ),
            const SizedBox(height: 10),

            // ── Description ─────────────────────────────────────────
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
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
                        : 'Start time',
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
                        : 'End time',
                    onTap: () => _pickTime(isStart: false),
                    accent: accent,
                    faded: _timeEnd == null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Notification ────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: _enableNotification
                    ? accent.withValues(alpha: 0.08)
                    : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _enableNotification
                      ? accent.withValues(alpha: 0.4)
                      : Colors.transparent,
                ),
              ),
              child: SwitchListTile.adaptive(
                dense: true,
                value: _enableNotification,
                onChanged: (v) {
                  if (!AppSettings.instance.notificationsEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Enable notifications in Settings first')),
                    );
                    return;
                  }
                  if (_timeStart == null && v) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Set a start time first')),
                    );
                    return;
                  }
                  setState(() => _enableNotification = v);
                },
                title: Text('Remind me',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _enableNotification ? accent : null)),
                subtitle: Text(
                  _enableNotification
                      ? AppSettings.timingLabel(
                      AppSettings.instance.notificationMinutesBefore)
                      : 'Tap to set a reminder',
                  style: TextStyle(fontSize: 12),
                ),
                secondary:
                Icon(Icons.notifications_outlined, color: _enableNotification ? accent : null),
                activeColor: accent,
              ),
            ),
            const SizedBox(height: 14),

            // ── Difficulty ──────────────────────────────────────────
            _DifficultyPicker(
              selected: _selectedDifficulty,
              onChanged: (d) => setState(() => _selectedDifficulty = d),
            ),
            const SizedBox(height: 14),

            // ── Category + Group ────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryPicker(
                  selectedCategory: _selectedCategory,
                  onChanged: (c) =>
                      setState(() => _selectedCategory = c),
                ),
                if (widget.showGroupPicker)
                  GroupPicker(
                    groups: _groups,
                    selected: _selectedGroup,
                    onChanged: (g) =>
                        setState(() => _selectedGroup = g),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Color ───────────────────────────────────────────────
            Text('Color',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600)),
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
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _handleSave,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Changes',
                    style: TextStyle(fontSize: 16)),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(_next),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: status.color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 14, color: status.color),
            const SizedBox(width: 4),
            Text(status.label,
                style: TextStyle(
                    fontSize: 12,
                    color: status.color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Reuse difficulty & picker button from add form ────────────────────────────

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker(
      {required this.selected, required this.onChanged});
  final Difficulty selected;
  final ValueChanged<Difficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Difficulty',
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface)),
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
                          Text(diff.label,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: diff.color,
                                  fontWeight: FontWeight.w600)),
                          Text('+${diff.points}pts',
                              style: TextStyle(
                                  fontSize: 9, color: diff.color)),
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
            color: faded
                ? theme.dividerColor
                : accent.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(10),
          color: faded ? Colors.transparent : accent.withValues(alpha: 0.06),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14, color: faded ? Colors.grey : accent),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 12,
                    color:
                    faded ? Colors.grey.shade500 : accent,
                    fontWeight: faded
                        ? FontWeight.normal
                        : FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}