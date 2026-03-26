import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

import '../../models/colors.dart';
import '../../models/difficulty.dart';
import '../../models/group.dart';
import '../../models/status.dart';
import '../../models/task.dart';
import '../../services/category_services.dart';
import '../../services/color_services.dart';
import '../../services/group_task_service.dart';
import '../../services/task_services.dart';
import '../pickers/color_picker.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({
    super.key,
    this.preselectedGroup,
    this.preselectedDate,
  });

  final Group? preselectedGroup;
  final DateTime? preselectedDate;

  static void show(
      BuildContext context, {
        Group? preselectedGroup,
        DateTime? preselectedDate,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => AddTaskSheet(
        preselectedGroup: preselectedGroup,
        preselectedDate: preselectedDate,
      ),
    );
  }

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _colorServices = ColorServices();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  var _selectedCategory = categoryServices.getCategories().values.firstOrNull;
  var _selectedDifficulty = Difficulty.easy;
  ColorsToPick? _selectedColor;
  Group? _selectedGroup; // null = personal
  late DateTime _selectedDate;
  TimeOfDay? _timeStart;
  TimeOfDay? _timeEnd;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.preselectedDate ?? DateTime.now();
    _selectedGroup = widget.preselectedGroup;
    _selectedColor = _colorServices.getColors().values.firstOrNull;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (p != null) setState(() => _selectedDate = p);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final p = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_timeStart ?? TimeOfDay.now())
          : (_timeEnd ?? TimeOfDay.now()),
    );
    if (p != null) setState(() => isStart ? _timeStart = p : _timeEnd = p);
  }

  void _save() {
    final t = AppLocalizations.of(context);
    final titleText = _titleController.text.trim();
    if (titleText.isEmpty) {
      setState(() => _titleError = t?.titleCannotBeEmpty ?? 'Title cannot be empty');
      return;
    }
    if (_selectedCategory == null) return;

    final task = Task(
      title: titleText,
      status: Status.todo,
      category: _selectedCategory!,
      description: _descController.text,
      color: _selectedColor?.color ?? Colors.transparent,
      date: _selectedDate,
      group: _selectedGroup,
      difficulty: _selectedDifficulty,
      timeStart: _timeStart ?? const TimeOfDay(hour: 0, minute: 0),
      timeEnd: _timeEnd ?? const TimeOfDay(hour: 0, minute: 0),
    );

    Navigator.of(context).pop();
    if (_selectedGroup == null) {
      unawaited(taskServices.addTask(task));
    } else {
      groupTaskService.addTask(_selectedGroup!.id, task);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (FirebaseAuth.instance.currentUser == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
            child: Text(t?.signInToUseGroups ?? 'Sign in to add tasks')),
      );
    }

    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final onAccent =
    accent.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;

    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Coloured header ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: accent,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
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
                      Icon(Icons.add_task_rounded,
                          color: onAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        t?.newTask ?? 'New Task',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: onAccent),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ──────────────────────────────────
                    TextField(
                      controller: _titleController,
                      autofocus: true,
                      decoration: _inputDeco(
                        label: t?.taskTitleLabel ?? 'Task title',
                        icon: Icons.title,
                        accent: accent,
                        errorText: _titleError,
                      ),
                      onChanged: (_) {
                        if (_titleError != null) {
                          setState(() => _titleError = null);
                        }
                      },
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 10),

                    // ── Description ────────────────────────────
                    TextField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: _inputDeco(
                        label: t?.descriptionOptional ?? 'Description (optional)',
                        icon: Icons.notes,
                        accent: accent,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Date & Time ────────────────────────────
                    _SectionLabel(t?.dateAndTime ?? 'Date & Time', accent),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: _PillButton(
                            icon: Icons.calendar_today_outlined,
                            label: _fmtDate(_selectedDate),
                            accent: accent,
                            active: true,
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: _PillButton(
                            icon: Icons.access_time,
                            label: _timeStart != null
                                ? _fmtTime(_timeStart!)
                                : (t?.startLabel ?? 'Start'),
                            accent: accent,
                            active: _timeStart != null,
                            onTap: () => _pickTime(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: _PillButton(
                            icon: Icons.timer_outlined,
                            label: _timeEnd != null
                                ? _fmtTime(_timeEnd!)
                                : (t?.endLabel ?? 'End'),
                            accent: accent,
                            active: _timeEnd != null,
                            onTap: () => _pickTime(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Difficulty ─────────────────────────────
                    _SectionLabel(t?.difficulty ?? 'Difficulty', accent),
                    const SizedBox(height: 8),
                    Row(
                      children: Difficulty.values.map((d) {
                        final sel = _selectedDifficulty == d;
                        return Expanded(
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedDifficulty = d),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? d.color.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sel
                                        ? d.color
                                        : theme.dividerColor,
                                    width: sel ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(d.icon, color: d.color, size: 22),
                                    const SizedBox(height: 2),
                                    Text(
                                      _difficultyLabel(d, t),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: d.color,
                                          fontWeight: sel
                                              ? FontWeight.w700
                                              : FontWeight.w500),
                                    ),
                                    Text('+${d.points}pts',
                                        style: TextStyle(
                                            fontSize: 9, color: d.color)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── Category ───────────────────────────────
                    _SectionLabel(t?.category ?? 'Category', accent),
                    const SizedBox(height: 8),
                    ListenableBuilder(
                      listenable: categoryServices,
                      builder: (context, _) {
                        final cats = categoryServices
                            .getCategories()
                            .values
                            .toList();
                        return _ChipRow(
                          children: cats.map((cat) {
                            final sel =
                                _selectedCategory?.id == cat.id ||
                                    _selectedCategory?.name == cat.name;
                            return _InlineChip(
                              label: cat.name,
                              color: cat.color,
                              selected: sel,
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Group ──────────────────────────────────
                    _SectionLabel(t?.group ?? 'Group', accent),
                    const SizedBox(height: 8),
                    ListenableBuilder(
                      listenable: groupTaskService,
                      builder: (context, _) {
                        return _ChipRow(
                          children: [
                            _InlineChip(
                              label: t?.personalCategory ?? 'Personal',
                              color: Colors.grey.shade500,
                              selected: _selectedGroup == null,
                              icon: Icons.person_outline,
                              onTap: () =>
                                  setState(() => _selectedGroup = null),
                            ),
                            ...groupTaskService.groups.map((g) {
                              final sel = _selectedGroup?.id == g.id;
                              return _InlineChip(
                                label: g.name,
                                color: g.color,
                                selected: sel,
                                icon: Icons.group_outlined,
                                onTap: () =>
                                    setState(() => _selectedGroup = g),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Color ──────────────────────────────────
                    _SectionLabel(t?.taskColor ?? 'Task color', accent),
                    const SizedBox(height: 8),
                    ColorPicker(
                      colorServices: _colorServices,
                      selectedColor: _selectedColor,
                      onTap: (name) {
                        setState(() {
                          _colorServices.updateColor(name, true);
                          _selectedColor =
                          _colorServices.getColors()[name];
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Save ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _save,
                        icon: const Icon(Icons.check_rounded),
                        label: Text(
                          t?.saveTask ?? 'Save Task',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
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

  InputDecoration _inputDeco({
    required String label,
    required IconData icon,
    required Color accent,
    String? errorText,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: accent),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accent, width: 2),
      ),
      errorText: errorText,
    );
  }
}

// ── Small shared widgets ──────────────────────────────────────────────────────

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
              color: accent, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.65))),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color accent;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: active ? accent : Colors.grey.shade400,
            width: active ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 12,
                color: active ? accent : Colors.grey.shade500),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    color: active ? accent : Colors.grey.shade500,
                    fontWeight: active
                        ? FontWeight.w600
                        : FontWeight.normal),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _InlineChip extends StatelessWidget {
  const _InlineChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

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
          boxShadow: selected
              ? [
            BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
            ] else ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: selected ? fg.withValues(alpha: 0.8) : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}