import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/task.dart';
import '../../models/status.dart';
import '../../services/group_task_service.dart';
import '../../services/task_services.dart';
import 'delete_confirmation_dialog.dart';
import 'status_checkbox.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  const TaskTile({super.key, required this.task});

  void _cycleStatus(Task t) {
    final next = switch (t.status) {
      Status.todo => Status.inProgress,
      Status.inProgress => Status.done,
      Status.done => Status.todo,
    };
    taskServices.updateTask(t.copyWith(status: next));
  }
  Group? _group() {
    final gid = task.group?.id;
    if (gid == null) return null;
    try {
      return groupTaskService.groups.firstWhere((g) => g.id == gid);
    } catch (_) {
      return task.group;
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = task.status == Status.done;
    final group = _group();
    final groupId = task.group?.id;


    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Dismissible(
        key: Key(task.id),
        direction: DismissDirection.horizontal,
        confirmDismiss: (_) async =>
        await const DeleteConfirmationDialog().show(context) ?? false,
        onDismissed: (_) {
          if (groupId != null) {
            groupTaskService.deleteTask(groupId, task.id);
          } else {
            taskServices.deleteTask(task);
          }
        },
        background: _SwipeBackground(alignment: Alignment.centerLeft),
        secondaryBackground: _SwipeBackground(alignment: Alignment.centerRight),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 7, color: task.color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          StatusCheckbox(
                            status: task.status,
                            onTap: () => {
                             _cycleStatus(task)
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                    color: isDone
                                        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    _CategoryChip(
                                      label: task.category.name,
                                      color: task.category.color,
                                    ),
                                    const SizedBox(width: 6),
                                    //_DifficultyBadge(task: task),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            task.formatDate(task.date),
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  final Alignment alignment;
  const _SwipeBackground({required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 22),
          SizedBox(width: 6),
          Text('Usuń',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

