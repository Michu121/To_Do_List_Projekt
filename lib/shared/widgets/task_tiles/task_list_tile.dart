// lib/shared/widgets/task_tiles/task_list_tile.dart
//
// The canonical task tile used on the home feed AND in group detail.
//
// HOW STATUS UPDATE WORKS (same as homepage.dart):
//   • personal task  (task.group == null)  → taskServices.updateTask()
//   • group task     (task.group != null)  → groupTaskService.updateTask(groupId, ...)
//
// HOW DELETE WORKS:
//   • everyTaskService.removeTask(groupId, task) handles both cases internally:
//       - resolves the correct groupId even for old tasks missing the group field
//       - calls groupTaskService.deleteTask() or taskServices.deleteTask()

import 'package:flutter/material.dart';

import '../../models/status.dart';
import '../../models/task.dart';
import '../../services/every_task_service.dart';
import '../../services/group_task_service.dart';
import '../../services/task_services.dart';
import 'delete_confirmation_dialog.dart';
import 'difficulty_badge.dart';
import 'dismissible_remove_background.dart';
import 'status_checkbox.dart';
import 'task_chip.dart';

class TaskListTile extends StatefulWidget {
  const TaskListTile({super.key, required this.task});

  final Task task;

  @override
  State<TaskListTile> createState() => _TaskListTileState();
}

class _TaskListTileState extends State<TaskListTile> {
  // Cycles todo → inProgress → done → todo
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
      // Personal task — goes to users/{uid}/tasks
      taskServices.updateTask(updated);
    } else {
      // Group task — goes to groups/{groupId}/tasks
      groupTaskService.updateTask(groupId, updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.task.group?.id;
    final isDone = widget.task.status == Status.done;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      // Red shown behind the sliding tile as the swipe-delete background.
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Dismissible(
        // Key includes groupId so personal and group tasks with the same
        // task-id never collide in the widget tree.
        key: ValueKey('task_${widget.task.id}_${groupId ?? "personal"}'),
        dismissThresholds: const {DismissDirection.horizontal: 0.3},
        direction: DismissDirection.horizontal,
        background: const DismissibleRemoveBackground(
            mainAxisAlignment: MainAxisAlignment.start),
        secondaryBackground: const DismissibleRemoveBackground(
            mainAxisAlignment: MainAxisAlignment.end),
        confirmDismiss: (_) => const DeleteConfirmationDialog().show(context),
        // everyTaskService resolves personal vs group internally
        onDismissed: (_) =>
            everyTaskService.removeTask(groupId, widget.task),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border(
                left: BorderSide(color: widget.task.color, width: 4)),
          ),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    // ── Title ──────────────────────────────────────────
                    Text(
                      widget.task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration:
                        isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // ── Bottom row: difficulty + chips ─────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DifficultyBadge(task: widget.task),
                        // Flexible prevents RenderFlex overflow when
                        // category or group names are long.
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
                              if (widget.task.group != null) ...[
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
    );
  }
}