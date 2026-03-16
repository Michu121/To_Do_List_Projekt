import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/colors.dart';
import '../models/difficulty.dart';
import '../models/group.dart';
import '../models/status.dart';
import '../models/task.dart';
import '../services/category_services.dart';
import '../services/color_services.dart';
import '../services/group_services.dart';
import '../services/task_services.dart';
import 'color_picker.dart';
import 'dropdown_category_picker.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddTaskSheet(),
    );
  }

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final ColorServices _colorServices = ColorServices();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  Category? _selectedCategory;
  ColorsToPick? _selectedColor;
  Difficulty _selectedDifficulty = Difficulty.easy;
  Group? _selectedGroup;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final categories = categoryServices.getCategories().values;
    _selectedCategory = categories.isNotEmpty ? categories.first : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleSave(BuildContext context) {
    final title = _titleController.text.trim();

    if (_selectedCategory == null) {
      setState(() => _errorText = 'Wybierz kategorię');
      return;
    }

    if (title.isNotEmpty) {
      taskServices.addTask(
        Task(
          title: title,
          status: Status.todo,
          category: _selectedCategory!,
          description: _descController.text,
          color: _selectedColor?.color ?? Colors.grey.shade300,
          date: DateTime.now(),
          difficulty: _selectedDifficulty,
          group: _selectedGroup,
        ),
      );
      Navigator.of(context).pop();
    } else {
      setState(() => _errorText = 'Tytuł nie może być pusty');
    }
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
      child: SingleChildScrollView(
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
                'Nowe Zadanie',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tytuł',
                errorText: _errorText,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.title),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Opis',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            const Text('Poziom trudności', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            _DifficultyPicker(
              selected: _selectedDifficulty,
              onChanged: (d) => setState(() => _selectedDifficulty = d),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kategoria', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 6),
                      DropDownCategoryPicker(
                        selectedCategory: _selectedCategory,
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Grupa', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 6),
                      _GroupPicker(
                        selectedGroup: _selectedGroup,
                        onChanged: (g) => setState(() => _selectedGroup = g),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Kolor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            ColorPicker(
              colorServices: _colorServices,
              selectedColor: _selectedColor,
              onTap: (name) {
                setState(() {
                  _colorServices.updateColor(name, true);
                  _selectedColor = _colorServices.getColors()[name];
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _handleSave(context),
                child: Text(
                  'Zapisz  (+${_selectedDifficulty.points} pkt)',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  final Difficulty selected;
  final ValueChanged<Difficulty> onChanged;
  const _DifficultyPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Difficulty.values.map((d) {
        final isSelected = d == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? d.color.withOpacity(0.15) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? d.color : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(d.icon, color: isSelected ? d.color : Colors.grey, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    d.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? d.color : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '+${d.points} pkt',
                    style: TextStyle(fontSize: 10, color: isSelected ? d.color : Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GroupPicker extends StatelessWidget {
  final Group? selectedGroup;
  final ValueChanged<Group?> onChanged;
  const _GroupPicker({required this.selectedGroup, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final groups = groupServices.getGroups();

    return GestureDetector(
      onTap: () => _showPicker(context, groups),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
          color: selectedGroup?.color.withOpacity(0.1) ?? Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedGroup?.name ?? 'Brak',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, List<Group> groups) {
    FocusScope.of(context).unfocus();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wybierz grupę'),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              children: [
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.grey),
                  title: const Text('Brak grupy'),
                  onTap: () {
                    onChanged(null);
                    Navigator.pop(ctx);
                  },
                ),
                ...groups.map(
                      (g) => ListTile(
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: g.color,
                      child: Text(g.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    title: Text(g.name),
                    onTap: () {
                      onChanged(g);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}