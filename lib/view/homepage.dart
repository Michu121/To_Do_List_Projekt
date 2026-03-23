// lib/view/homepage.dart
//
// Only contains HomePage (auth gate) and _TaskFeed (page body).
// All sub-widgets have been extracted to their own files:
//
//   TaskListTile   → lib/shared/widgets/task_tiles/task_list_tile.dart
//   TaskChip       → lib/shared/widgets/task_tiles/task_chip.dart
//   DifficultyBadge→ lib/shared/widgets/task_tiles/difficulty_badge.dart
//   CategoryBar    → lib/shared/widgets/category/category_bar.dart
//   DateSection    → lib/shared/widgets/category/date_section.dart
//   groupTasksByDate→lib/shared/widgets/category/date_section.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:todo_list/l10n/app_localizations.dart';
import 'package:todo_list/shared/services/category_services.dart';

import '../shared/models/category.dart';
import '../shared/services/every_task_service.dart';
import '../shared/widgets/add_forms/add_category_form.dart';
import '../shared/widgets/category/category_bar.dart';
import '../shared/widgets/category/date_section.dart';

// Stable "All" sentinel at file scope — its object identity never changes
// across rebuilds, which makes the equality check in _guardSelectedCategory
// work correctly.
final _allCategory =
Category(name: 'All', color: Colors.grey.withValues(alpha: 0.90));

// ── Page ──────────────────────────────────────────────────────────────────────

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

// ── Task feed ─────────────────────────────────────────────────────────────────

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

  /// If the selected category was deleted while the app was open, fall back.
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
        // ── Category header ───────────────────────────────────────────
        ListenableBuilder(
          listenable: categoryServices,
          builder: (context, _) {
            _guardSelectedCategory();
            final categories = _buildCategoryList();
            final allTasks = everyTaskService.getTasks();

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
                        onPressed: () => CategoryOverlay.show(context),
                        child: const Text('+Kategoria',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  // CategoryBar is the extracted scrollable chip row
                  CategoryBar(
                    categories: categories,
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

        // ── Task list ─────────────────────────────────────────────────
        Expanded(
          child: ListenableBuilder(
            listenable: everyTaskService,
            builder: (context, _) {
              if (everyTaskService.loading) {
                return const Center(child: CircularProgressIndicator());
              }

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
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                      fontSize: 20,
                    ),
                  ),
                );
              }

              // groupTasksByDate is the extracted helper function
              final sections = groupTasksByDate(filtered);

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: sections.length + 1,
                itemBuilder: (context, index) {
                  // Extra bottom padding so FAB doesn't overlap last tile
                  if (index == sections.length) {
                    return const SizedBox(height: 80);
                  }
                  final s = sections[index];
                  // DateSection renders the label + list of TaskListTiles
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