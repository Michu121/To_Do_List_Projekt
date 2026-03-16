import 'package:flutter/material.dart';
import 'package:todo_list/l10n/app_localizations.dart';

import '../shared/models/category.dart';
import '../shared/services/category_services.dart';
import '../shared/services/color_services.dart';
import '../shared/services/task_services.dart';
import '../shared/widgets/task_list_tile.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedCategoryName;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: Listenable.merge([taskServices, categoryServices]),
      builder: (context, _) {
        final allTasks = taskServices.getTasks();
        final categories = categoryServices.getCategories();

        final filtered = _selectedCategoryName == null
            ? allTasks
            : allTasks.where((t) => t.category.name == _selectedCategoryName).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CategoryFilterBar(
              categories: categories,
              selected: _selectedCategoryName,
              onSelected: (name) => setState(() {
                _selectedCategoryName = name;
              }),
              onAddCategory: _showAddCategorySheet,
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                child: Text(
                  t.notask,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 20,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: filtered.length + 1,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  if (index == filtered.length) {
                    return const SizedBox(height: 90);
                  }
                  return TaskTile(task: filtered[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddCategorySheet(),
    );
  }
}

// ── Category Filter Bar ───────────────────────────────────────────────────────

class _CategoryFilterBar extends StatelessWidget {
  final Map<String, Category> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final void Function(BuildContext) onAddCategory;

  const _CategoryFilterBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
    required this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAllSelected = selected == null;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black..withValues(alpha:0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Text(
                  'Kategorie',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface..withValues(alpha:0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => onAddCategory(context),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 2),
                      Text(
                        'Dodaj',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              physics: const BouncingScrollPhysics(),
              children: [
                _FilterChip(
                  label: 'Wszystkie',
                  color: theme.colorScheme.primary,
                  isSelected: isAllSelected,
                  onTap: () => onSelected(null),
                ),
                ...categories.entries.map((e) => _FilterChip(
                  label: e.key,
                  color: e.value.color,
                  isSelected: selected == e.key,
                  onTap: () => onSelected(selected == e.key ? null : e.key),
                  onLongPress: () => _showDeleteDialog(context, e.key),
                )),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń kategorię'),
        content: Text('Czy na pewno chcesz usunąć "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              categoryServices.deleteCategory(name);
              Navigator.pop(ctx);
            },
            child: const Text('Usuń', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color..withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color..withValues(alpha:0.35),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}

// ── Add Category Sheet ────────────────────────────────────────────────────────

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet();

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _nameController = TextEditingController();
  final _colorServices = ColorServices();
  Color _selectedColor = Colors.blue;
  String? _error;

  static const List<Color> _palette = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nazwa nie może być pusta');
      return;
    }
    if (categoryServices.getCategories().containsKey(name)) {
      setState(() => _error = 'Kategoria o tej nazwie już istnieje');
      return;
    }
    categoryServices.addCategory(Category(name: name, color: _selectedColor));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Nowa Kategoria',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nazwa',
              errorText: _error,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.label_outline),
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 20),
          const Text('Kolor', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _palette.map((c) {
              final isSelected = _selectedColor == c;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: c..withValues(alpha:0.5), blurRadius: 6, spreadRadius: 1)]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedColor..withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _selectedColor..withValues(alpha:0.4)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _nameController.text.isEmpty
                        ? 'Podgląd'
                        : _nameController.text,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _save,
                    child: const Text('Zapisz', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}