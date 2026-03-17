import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:todo_list/l10n/app_localizations.dart';
import 'package:todo_list/shared/services/task_services.dart';
import '../shared/models/group.dart';
import '../shared/models/status.dart';
import '../shared/models/task.dart';
import '../shared/services/every_task_service.dart';
import '../shared/services/group_task_service.dart';
import '../shared/widgets/task_tiles/delete_confirmation_dialog.dart';
import '../shared/widgets/task_tiles/dismissible_remove_background.dart';
import '../shared/widgets/task_tiles/status_checkbox.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (authSnap.data == null) {
          return _SignInPrompt();
        }
        return _TaskFeed();
      },
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64,
              color: Colors.blueAccent.withValues(alpha: 0.35)),
          const SizedBox(height: 20),
          Text(
            'Sign in to see your tasks',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to Profile to log in or register',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: everyTaskService,
      builder: (context, _) {
        if (everyTaskService.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = everyTaskService.getTasks();

        if (tasks!.isEmpty) {
          return Center(
            child: Text(
              t.notask,
              style: TextStyle(
                  color: Theme.of(context).primaryColor, fontSize: 20),
            ),
          );
        }

        final sections = _groupByDate(tasks);

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: sections.length + 1,
          itemBuilder: (context, index) {
            if (index == sections.length) return const SizedBox(height: 80);
            final s = sections[index];
            return _DateSection(label: s.label, tasks: s.tasks);
          },
        );
      },
    );
  }

  List<_Section> _groupByDate(List<Task> tasks) {
    final map = <String, List<Task>>{};
    for (final t in tasks) {
      final key = '${t.date.year}-${t.date.month}-${t.date.day}';
      map.putIfAbsent(key, () => []).add(t);
    }
    final keys = map.keys.toList()..sort();
    return keys.map((k) => _Section(label: k, tasks: map[k]!)).toList();
  }
}

class _Section {
  final String label;
  final List<Task> tasks;
  _Section({required this.label, required this.tasks});
}

class _DateSection extends StatelessWidget {
  const _DateSection({required this.label, required this.tasks});
  final String label;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(
            _formatLabel(label),
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
        ...tasks.map((t) => GroupTaskListTile(task: t)),
      ],
    );
  }

  String _formatLabel(String isoKey) {
    final parts = isoKey.split('-');
    if (parts.length != 3) return isoKey;
    final date = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    if (date == today) return 'TODAY';
    if (date == tomorrow) return 'TOMORROW';
    final months = [
      'JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class GroupTaskListTile extends StatelessWidget {
  const GroupTaskListTile({super.key, required this.task});
  final Task task;

  Status _nextStatus(Status s) {
    switch (s) {
      case Status.todo:
        return Status.inProgress;
      case Status.inProgress:
        return Status.done;
      case Status.done:
        return Status.todo;
    }
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
    final groupId = task.group?.id;
    final group = _group();
    final isDone = task.status == Status.done;
    
    String formatLabel(String isoKey) {
      final parts = isoKey.split('.');
      if (parts.length != 3) return isoKey;
      final date = DateTime(
          int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      if (date == today) return 'TODAY';
      if (date == tomorrow) return 'TOMORROW';
      final months = [
        'JAN','FEB','MAR','APR','MAY','JUN',
        'JUL','AUG','SEP','OCT','NOV','DEC'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Dismissible(
        key: Key(task.id),
        direction: DismissDirection.horizontal,
        background: const DismissibleRemoveBackground(
          mainAxisAlignment: MainAxisAlignment.start,
        ),
        secondaryBackground: const DismissibleRemoveBackground(
          mainAxisAlignment: MainAxisAlignment.end,
        ),
        confirmDismiss: (_) => const DeleteConfirmationDialog().show(context),
        onDismissed: (_) {
          everyTaskService.removeTask(groupId, task);
        },
        dismissThresholds: <DismissDirection, double>{
          DismissDirection.horizontal: 20,
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border(
                left: BorderSide(color: task.color, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              StatusCheckbox(
                status: task.status,
                onTap: () {
                  if (groupId == null) {
                    taskServices.updateTask(
                      task.copyWith(status: _nextStatus(task.status)),
                    );
                  } else {
                    groupTaskService.updateTask(
                    groupId,
                    task.copyWith(status: _nextStatus(task.status)),
                  );
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: isDone ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DifficultyBadge(task: task),
                        Row(
                          children: [
                            _Chip(
                              label: task.category.name,
                              color: task.category.color,
                            ),
                            if (group != null) ...[
                            const SizedBox(width: 6),
                              _Chip(
                                label: group.name,
                                color: group.color,
                                icon: Icons.group,
                              ),
                          ],


                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatLabel(task.formatDate(task.date)),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, this.icon});
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
          Text(
            label,
            style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _NoGroupsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add, size: 72,
              color: Colors.blueAccent.withValues(alpha: 0.25)),
          const SizedBox(height: 20),
          Text(
            'Join or create a group',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tasks shared in groups will appear here',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}
class _DifficultyBadge extends StatelessWidget {
  final Task task;
  const _DifficultyBadge({required this.task});

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
          style: TextStyle(fontSize: 11, color: d.color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}