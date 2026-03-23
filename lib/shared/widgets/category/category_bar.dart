// lib/shared/widgets/category/category_bar.dart
//
// Horizontal scrollable bar of category filter buttons shown at the top of
// the home feed. Extracted from homepage.dart.
//
// CategoryBar       — the scrollable row
// CategoryBarButton — individual button (selected / unselected state)

import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/task.dart';
import '../add_forms/add_category_form.dart';

// ── Bar ───────────────────────────────────────────────────────────────────────

class CategoryBar extends StatelessWidget {
  const CategoryBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    required this.allTasks,
  });

  final List<Category> categories;
  final Category selectedCategory;
  final ValueChanged<Category> onSelected;
  // Pass in the full task list so each button can show a count.
  final List<Task> allTasks;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map((cat) => CategoryBarButton(
                  cat: cat,
                  tasksInCategory: allTasks
                      .where((t) =>
                          cat.name == 'All' || t.category.id == cat.id)
                      .length,
                  selectedCategory: selectedCategory,
                  onSelected: onSelected,
                ))
            .toList(),
      ),
    );
  }
}

// ── Button ────────────────────────────────────────────────────────────────────

class CategoryBarButton extends StatelessWidget {
  const CategoryBarButton({
    super.key,
    required this.cat,
    required this.tasksInCategory,
    required this.selectedCategory,
    required this.onSelected,
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
      // Long-press opens the category edit overlay (not available for "All").
      onLongPress:
          isAll ? null : () => CategoryOverlay.show(context, cat: cat),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
        child: Text(
          '${cat.name} ($tasksInCategory)',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
