import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:todo_list/l10n/app_localizations.dart';
import 'package:todo_list/shared/services/category_services.dart';

import '../shared/models/category.dart';
import '../shared/services/every_task_service.dart';
import '../shared/widgets/add_forms/add_category_form.dart';
import '../shared/widgets/category/category_bar.dart';
import '../shared/widgets/category/date_section.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final allCategory = Category(
      id: '__all__',
      name: t?.allCategory ?? 'All',
      color: Colors.grey.withValues(alpha: 0.85),
    );
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return _TaskFeed(allCategory: allCategory);
      },
    );
  }
}

class _TaskFeed extends StatefulWidget {
  final Category allCategory;
  const _TaskFeed({required this.allCategory});

  @override
  State<_TaskFeed> createState() => _TaskFeedState();
}

class _TaskFeedState extends State<_TaskFeed> {
  late Category _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.allCategory;
  }

  @override
  void didUpdateWidget(_TaskFeed oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When locale changes, allCategory gets a new translated name.
    // If the user has the "All" virtual category selected, update its name
    // so the selection highlight still works correctly.
    if (_selectedCategory.id == '__all__') {
      _selectedCategory = widget.allCategory;
    }

    // Update the Default category display name in CategoryServices
    // without triggering a full re-init (no Firestore re-subscription needed).
    categoryServices.updateDefaultName(context);
  }

  List<Category> _buildList() => [
    widget.allCategory,
    ...categoryServices.getCategories().values,
  ];

  /// If the previously selected category no longer exists (e.g. it was deleted),
  /// fall back to "All". Uses id comparison so locale renames don't cause issues.
  void _guard() {
    if (_selectedCategory.id == '__all__') return;
    final exists = categoryServices
        .getCategories()
        .values
        .any((c) => c.id == _selectedCategory.id);
    if (!exists) {
      setState(() => _selectedCategory = widget.allCategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
                          t?.categories ?? 'Categories',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: onAccent.withValues(alpha: 0.9)),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: onAccent,
                          backgroundColor: onAccent.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => CategoryOverlay.show(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(t?.add ?? 'Add',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
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

              // Filter by id (stable) so renaming / locale change still works
              final filtered = _selectedCategory.id == '__all__'
                  ? tasks
                  : tasks
                  .where((t) =>
              t.category.id == _selectedCategory.id ||
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
                        t?.notask ?? 'No Task, Now you can rest',
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