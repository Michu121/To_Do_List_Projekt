import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/task.dart';
import '../add_forms/add_category_form.dart';

/// Built-in category names — long-press edit is disabled for these.
const _kDefaultNames = {'All',"Wszystkie", 'Default',"Domyślna"};

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
  final List<Task> allTasks;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map((cat) => CategoryBarButton(
          cat: cat,
          // Count by name so DB tasks (which may have different UUIDs)
          // are included in the count correctly.
          tasksInCategory: cat.name == 'All'|| cat.name == 'Wszystkie'
              ? allTasks.length
              : allTasks
              .where((t) => t.category.name == cat.name)
              .length,
          selectedCategory: selectedCategory,
          onSelected: onSelected,
        ))
            .toList(),
      ),
    );
  }
}

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
    // Compare by name so the stable '__all__' sentinel still works
    final isSelected = cat.name == selectedCategory.name;
    final isDefault = _kDefaultNames.contains(cat.name);

    final textColor = isSelected
        ? (cat.color.computeLuminance() > 0.45 ? Colors.black87 : Colors.white)
        : Colors.white;

    return InkWell(
      onTap: () => onSelected(cat),
      // Only non-default, non-All categories support long-press editing
      onLongPress:
      isDefault ? null : () => CategoryOverlay.show(context, cat: cat),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? cat.color : cat.color.withValues(alpha: 0.18),
          border: Border.all(
            color: isSelected ? cat.color : cat.color.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
            BoxShadow(
                color: cat.color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             isDefault ? Padding(
               padding: const EdgeInsets.only(right:2.0),
               child: const Icon(Icons.block, size: 16, color: Colors.white),
             )
                 :const SizedBox(),
            Text(
              '${cat.name} ($tasksInCategory)',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),

          ],
        ),
      ),
    );
  }
}