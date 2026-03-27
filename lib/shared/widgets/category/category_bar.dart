import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/task.dart';
import '../add_forms/add_category_form.dart';

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
          // For the virtual 'All' category use total count;
          // for others filter by category id so renaming still works.
          tasksInCategory: cat.id == '__all__'
              ? allTasks.length
              : allTasks
              .where((t) => t.category.id == cat.id || t.category.name == cat.name)
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

  /// A category is "default/protected" if it has the reserved virtual id
  /// (__all__) or the fixed default id (default).  We never use name strings
  /// here so the comparison stays correct after a locale change.
  bool get _isProtected => cat.id == '__all__' || cat.id == 'default';

  @override
  Widget build(BuildContext context) {
    // Compare by id so selection survives locale renames of the All category
    final isSelected = cat.id == selectedCategory.id;

    final textColor = isSelected
        ? (cat.color.computeLuminance() > 0.45 ? Colors.black87 : Colors.white)
        : Colors.white;

    return InkWell(
      onTap: () => onSelected(cat),
      // Only user-created (non-protected) categories support long-press editing
      onLongPress: _isProtected ? null : () => CategoryOverlay.show(context, cat: cat),
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
            if (_isProtected)
              Padding(
                padding: const EdgeInsets.only(right: 2.0),
                child: Icon(Icons.house, size: 16, color: Colors.white),
              ),
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