import 'package:flutter/material.dart';

import '../../models/status.dart';
import '../../models/task.dart';
import '../../services/every_task_service.dart';
import '../../services/group_task_service.dart';
import '../../services/task_services.dart';
import '../add_forms/task_edit_sheet.dart';
import 'delete_confirmation_dialog.dart';
import 'difficulty_badge.dart';
import 'dismissible_remove_background.dart';
import 'status_checkbox.dart';
import 'task_chip.dart';

class TaskListTile extends StatefulWidget {
  const TaskListTile({
    super.key,
    required this.task,
    this.showGroup = true,
  });

  final Task task;

  /// If false, hides the group chip and passes showGroupPicker:false to edit.
  final bool showGroup;

  @override
  State<TaskListTile> createState() => _TaskListTileState();
}

class _TaskListTileState extends State<TaskListTile> {
  Status _nextStatus(Status s) => switch (s) {
    Status.todo => Status.inProgress,
    Status.inProgress => Status.done,
    Status.done => Status.todo,
  };

  void _onStatusTap() {
    final updated =
    widget.task.copyWith(status: _nextStatus(widget.task.status));
    final groupId = widget.task.group?.id;
    if (groupId == null) {
      taskServices.updateTask(updated);
    } else {
      groupTaskService.updateTask(groupId, updated);
    }
  }

  void _onTap() {
    TaskEditSheet.show(
      context,
      task: widget.task,
      // Only show group picker for personal tasks or if showGroup is true
      showGroupPicker:
      widget.showGroup && widget.task.group == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.task.group?.id;
    final isDone = widget.task.status == Status.done;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Dismissible(
        key: ValueKey(
            'task_${widget.task.id}_${groupId ?? "personal"}'),
        dismissThresholds: const {
          DismissDirection.horizontal: 0.3
        },
        direction: DismissDirection.horizontal,
        background: const DismissibleRemoveBackground(
            mainAxisAlignment: MainAxisAlignment.start),
        secondaryBackground: const DismissibleRemoveBackground(
            mainAxisAlignment: MainAxisAlignment.end),
        confirmDismiss: (_) =>
            const DeleteConfirmationDialog().show(context),
        onDismissed: (_) =>
            everyTaskService.removeTask(groupId, widget.task),
        child: GestureDetector(
          onTap: _onTap,
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                  left: BorderSide(
                      color: widget.task.color, width: 4)),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            child: Row(
              children: [
                StatusCheckbox(
                  status: widget.task.status,
                  onTap: _onStatusTap,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title ──────────────────────────────────
                      Text(
                        widget.task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: isDone ? Colors.grey : null,
                        ),
                      ),
                      // ── Date/Time hint ─────────────────────────
                      if (widget.task.timeStart.hour != 0 ||
                          widget.task.timeStart.minute != 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 11,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.7)),
                              const SizedBox(width: 3),
                              Text(
                                _fmtTime(widget.task.timeStart),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.7)),
                              ),
                              if (widget.task.timeEnd.hour != 0 ||
                                  widget.task.timeEnd.minute != 0)
                                Text(
                                  ' → ${_fmtTime(widget.task.timeEnd)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.7)),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 5),

                      // ── Bottom row ─────────────────────────────
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          DifficultyBadge(task: widget.task),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: TaskChip(
                                    label: widget.task.category.name,
                                    color: widget.task.category.color,
                                  ),
                                ),
                                if (widget.showGroup &&
                                    widget.task.group != null) ...[
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: TaskChip(
                                      label: widget.task.group!.name,
                                      color: widget.task.group!.color,
                                      icon: Icons.group,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}