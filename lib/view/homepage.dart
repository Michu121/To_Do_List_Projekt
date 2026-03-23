import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:todo_list/l10n/app_localizations.dart';
import 'package:todo_list/shared/services/category_services.dart';

import '../shared/models/category.dart';
import '../shared/services/every_task_service.dart';
import '../shared/widgets/add_forms/add_category_form.dart';
import '../shared/widgets/category/category_bar.dart';
import '../shared/widgets/category/date_section.dart';

// Stable "All" sentinel — fixed id so comparison is consistent
final _allCategory = Category(
    id: '__all__', name: 'All', color: Colors.grey.withValues(alpha: 0.85));

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return const _TaskFeed();
      },
    );
  }
}

class _TaskFeed extends StatefulWidget {
  const _TaskFeed();

  @override
  State<_TaskFeed> createState() => _TaskFeedState();
}

class _TaskFeedState extends State<_TaskFeed> {
  Category _selectedCategory = _allCategory;

  List<Category> _buildList() => [
    _allCategory,
    ...categoryServices.getCategories().values,
  ];

  void _guard() {
    if (_selectedCategory.id == '__all__') return;
    final exists = categoryServices
        .getCategories()
        .values
        .any((c) => c.name == _selectedCategory.name);
    if (!exists) setState(() => _selectedCategory = _allCategory);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final onAccent =
    accent.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;

    return Column(
      children: [
        // ── Category bar ─────────────────────────────────────────
        ListenableBuilder(
          listenable: categoryServices,
          builder: (context, _) {
            _guard();
            final cats = _buildList();
            final allTasks = everyTaskService.getTasks();

            return Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              color: theme.appBarTheme.backgroundColor,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Text(
                          'Categories',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: onAccent.withValues(alpha: 0.9)),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: onAccent,
                          backgroundColor: onAccent.withValues(alpha: 0.15),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => CategoryOverlay.show(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  CategoryBar(
                    categories: cats,
                    selectedCategory: _selectedCategory,
                    allTasks: allTasks,
                    onSelected: (c) =>
                        setState(() => _selectedCategory = c),
                  ),
                ],
              ),
            );
          },
        ),

        // ── Task list ─────────────────────────────────────────────
        Expanded(
          child: ListenableBuilder(
            listenable: everyTaskService,
            builder: (context, _) {
              if (everyTaskService.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              final tasks = everyTaskService.getTasks();

              // ⚡ Filter by category NAME, not id — ensures tasks loaded
              // from Firestore (with embedded category ids that may differ
              // from the current session's default category ids) still match.
              final filtered = _selectedCategory.id == '__all__'
                  ? tasks
                  : tasks
                  .where((t) =>
              t.category.name == _selectedCategory.name)
                  .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checklist_rounded,
                          size: 72,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.15)),
                      const SizedBox(height: 16),
                      Text(
                        t.notask,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final sections = groupTasksByDate(filtered);
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: sections.length + 1,
                itemBuilder: (_, i) {
                  if (i == sections.length) {
                    return const SizedBox(height: 80);
                  }
                  final s = sections[i];
                  return DateSection(label: s.label, tasks: s.tasks);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}