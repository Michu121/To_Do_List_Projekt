import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:todo_list/l10n/app_localizations.dart';
import 'package:todo_list/shared/services/category_services.dart';
import 'package:todo_list/shared/services/task_services.dart';

import '../shared/models/category.dart';
import '../shared/models/status.dart';
import '../shared/models/task.dart';
import '../shared/services/every_task_service.dart';
import '../shared/services/group_task_service.dart';
import '../shared/widgets/add_forms/add_category_form.dart';
import '../shared/widgets/task_tiles/delete_confirmation_dialog.dart';
import '../shared/widgets/task_tiles/dismissible_remove_background.dart';
import '../shared/widgets/task_tiles/status_checkbox.dart';

// Stable "All" sentinel — defined here so it never changes identity
// across rebuilds, which would break category selection logic.
final _allCategory =
Category(name: 'All', color: Colors.grey.withValues(alpha: 0.90));

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
        return const _TaskFeed();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Task feed
// ═══════════════════════════════════════════════════════════════════════════════

class _TaskFeed extends StatefulWidget {
  const _TaskFeed();

  @override
  State<_TaskFeed> createState() => _TaskFeedState();
}

class _TaskFeedState extends State<_TaskFeed> {
  Category _selectedCategory = _allCategory;

  List<Category> _buildCategoryList() => [
    _allCategory,
    ...categoryServices.getCategories().values,
  ];

  /// If the selected category was deleted, fall back to "All".
  void _guardSelectedCategory() {
    if (_selectedCategory.name == 'All') return;
    final stillExists = categoryServices
        .getCategories()
        .values
        .any((c) => c.id == _selectedCategory.id);
    if (!stillExists) setState(() => _selectedCategory = _allCategory);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Category bar ──────────────────────────────────────────────────
        ListenableBuilder(
          listenable: categoryServices,
          builder: (context, _) {
            _guardSelectedCategory();
            final categories = _buildCategoryList();

            return Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: theme.appBarTheme.backgroundColor),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: Text(
                          'Kategorie',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        isSemanticButton: false,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                        ),
                        onPressed: () =>
                            CategoryOverlay.show(context),
                        child: const Text('+Kategoria',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  _CategoryChoseBar(
                    categories: categories,
                    selectedCategory: _selectedCategory,
                    onSelected: (c) =>
                        setState(() => _selectedCategory = c),
                  ),
                ],
              ),
            );
          },
        ),

        // ── Task list ─────────────────────────────────────────────────────
        Expanded(
          child: ListenableBuilder(
            listenable: everyTaskService,
            builder: (context, _) {
              if (everyTaskService.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              // getTasks() always returns List<Task> — no null check needed
              final tasks = everyTaskService.getTasks();
              final filtered = tasks
                  .where((task) =>
              _selectedCategory.name == 'All' ||
                  task.category.id == _selectedCategory.id)
                  .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    t.notask,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                      fontSize: 20,
                    ),
                  ),
                );
              }

              final sections = _groupByDate(filtered);

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: sections.length + 1,
                itemBuilder: (context, index) {
                  if (index == sections.length) {
                    return const SizedBox(height: 80);
                  }
                  final s = sections[index];
                  return _DateSection(
                      label: s.label, tasks: s.tasks);
                },
              );
            },
          ),
        ),
      ],
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

// ═══════════════════════════════════════════════════════════════════════════════
// Date section header + tiles
// ═══════════════════════════════════════════════════════════════════════════════

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
        ...tasks.map((t) => TaskListTile(task: t)),
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
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Task tile
// ═══════════════════════════════════════════════════════════════════════════════

class TaskListTile extends StatefulWidget {
  const TaskListTile({super.key, required this.task});
  final Task task;

  @override
  State<TaskListTile> createState() => _TaskListTileState();
}

class _TaskListTileState extends State<TaskListTile> {
  Status _nextStatus(Status s) => switch (s) {
    Status.todo => Status.inProgress,
    Status.inProgress => Status.done,
    Status.done => Status.todo,
  };

  @override
  Widget build(BuildContext context) {
    final groupId = widget.task.group?.id;
    final isDone = widget.task.status == Status.done;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Dismissible(
        key: ValueKey(
            'task_${widget.task.id}_${widget.task.group?.id ?? "no_group"}'),
        dismissThresholds: const {DismissDirection.horizontal: 0.3},
        direction: DismissDirection.horizontal,
        background: const DismissibleRemoveBackground(
            mainAxisAlignment: MainAxisAlignment.start),
        secondaryBackground: const DismissibleRemoveBackground(
            mainAxisAlignment: MainAxisAlignment.end),
        confirmDismiss: (_) =>
            const DeleteConfirmationDialog().show(context),
        onDismissed: (_) =>
            everyTaskService.removeTask(groupId, widget.task),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border(
                left: BorderSide(
                    color: widget.task.color, width: 4)),
          ),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              StatusCheckbox(
                status: widget.task.status,
                onTap: () {
                  final updated = widget.task.copyWith(
                      status: _nextStatus(widget.task.status));
                  if (groupId == null) {
                    taskServices.updateTask(updated);
                  } else {
                    groupTaskService.updateTask(groupId, updated);
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        _DifficultyBadge(task: widget.task),
                        // Flexible prevents RenderFlex overflow with
                        // long category/group names
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: _Chip(
                                  label: widget.task.category.name,
                                  color: widget.task.category.color,
                                ),
                              ),
                              if (widget.task.group != null) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: _Chip(
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

// ═══════════════════════════════════════════════════════════════════════════════
// Category bar
// ═══════════════════════════════════════════════════════════════════════════════

class _CategoryChoseBar extends StatelessWidget {
  const _CategoryChoseBar({
    required this.categories,
    required this.onSelected,
    required this.selectedCategory,
  });

  final List<Category> categories;
  final Category selectedCategory;
  final ValueChanged<Category> onSelected;

  @override
  Widget build(BuildContext context) {
    final allTasks = everyTaskService.getTasks();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map((cat) => _CategoryChoseButton(
          cat: cat,
          tasksInCategory: allTasks
              .where((t) =>
          cat.name == 'All' ||
              t.category.id == cat.id)
              .length,
          selectedCategory: selectedCategory,
          onSelected: onSelected,
        ))
            .toList(),
      ),
    );
  }
}

class _CategoryChoseButton extends StatelessWidget {
  const _CategoryChoseButton({
    required this.cat,
    required this.onSelected,
    required this.selectedCategory,
    required this.tasksInCategory,
  });

  final Category cat;
  final int tasksInCategory;
  final Category selectedCategory;
  final ValueChanged<Category> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = cat.id == selectedCategory.id;
    final isAll = cat.name == 'All';

    return InkWell(
      onTap: () => onSelected(cat),
      // "All" is not editable — only real categories get long-press
      onLongPress:
      isAll ? null : () => CategoryOverlay.show(context, cat: cat),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? cat.color
              : cat.color.withValues(alpha: 0.13),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.onSurface
                : cat.color,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 7),
        child: Text(
          '${cat.name} ($tasksInCategory)',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Supporting widgets
// ═══════════════════════════════════════════════════════════════════════════════

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
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600),
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
          style: TextStyle(
              fontSize: 11,
              color: d.color,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}